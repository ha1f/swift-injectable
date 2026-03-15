import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

/// @Hook マクロ。stored var を Storage クラスに移動し、DynamicProperty 準拠を追加する。
public struct HookMacro {}

// MARK: - MemberMacro（Storage, hookStorage, init 生成）

extension HookMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard declaration.is(StructDeclSyntax.self) else {
            throw DiagnosticsError(message: "@Hook can only be applied to structs")
        }

        // @State の誤用を警告
        warnStateProperties(in: declaration, context: context)

        let storedVars = extractStoredVars(from: declaration, in: context)

        // stored var がなければ Storage は生成しない
        if storedVars.isEmpty {
            return []
        }

        // access control
        let accessLevel: String
        if let structDecl = declaration.as(StructDeclSyntax.self) {
            let modifiers = structDecl.modifiers.map { $0.trimmedDescription }
            if modifiers.contains("public") {
                accessLevel = "public "
            } else {
                accessLevel = ""
            }
        } else {
            accessLevel = ""
        }

        // Storage クラス
        let storageProperties = storedVars.map { sv -> String in
            let propAccess = sv.storageAccessModifier(structAccessLevel: accessLevel)
            return "    \(propAccess)var \(sv.name): \(sv.type)"
        }.joined(separator: "\n")

        // private なプロパティは init パラメータから除外
        let publicVars = storedVars.filter { !$0.isPrivateAccess }
        let privateVars = storedVars.filter { $0.isPrivateAccess }

        let initParams = publicVars.map {
            "        \($0.name): \($0.type)"
        }.joined(separator: ",\n")

        let initBodyPublic = publicVars.map {
            "            self.\($0.name) = \($0.name)"
        }
        let initBodyPrivate = privateVars.map {
            "            self.\($0.name) = \($0.defaultValue!)"
        }
        let initBody = (initBodyPublic + initBodyPrivate).joined(separator: "\n")

        let storageDecl: DeclSyntax = """
            @Observable
            \(raw: accessLevel)final class Storage {
            \(raw: storageProperties)
                init(
            \(raw: initParams)
                ) {
            \(raw: initBody)
                }
            }
            """

        // hookStorage プロパティ
        let storageProperty: DeclSyntax = """
            @SwiftUI.State private var hookStorage: Storage
            """

        // binding プロパティ（Binding<Storage> を返す）
        let bindingProperty: DeclSyntax = """
            \(raw: accessLevel)var binding: SwiftUI.Binding<Storage> {
                $hookStorage
            }
            """

        // init（private なプロパティはパラメータから除外）
        let hookInitParams = publicVars.map { sv in
            if let defaultValue = sv.defaultValue {
                return "        \(sv.name): \(sv.type) = \(defaultValue)"
            } else {
                return "        \(sv.name): \(sv.type)"
            }
        }.joined(separator: ",\n")

        // init accessor で初期化されるダミーバッキングストレージの初期化
        let dummyInitsPublic = publicVars.map {
            "    self.\($0.name) = \($0.name)"
        }
        let dummyInitsPrivate = privateVars.map {
            "    self.\($0.name) = \($0.defaultValue!)"
        }
        let dummyInits = (dummyInitsPublic + dummyInitsPrivate).joined(separator: "\n")

        let storageInitArgs = publicVars.map {
            "            \($0.name): \($0.name)"
        }.joined(separator: ",\n")

        let hookInit: DeclSyntax = """
            \(raw: accessLevel)init(
            \(raw: hookInitParams)
            ) {
            \(raw: dummyInits)
                _hookStorage = SwiftUI.State(initialValue: Storage(
            \(raw: storageInitArgs)
                ))
            }
            """

        return [storageDecl, storageProperty, bindingProperty, hookInit]
    }
}

// MARK: - MemberAttributeMacro（stored var に @_HookAccessor 付与）

extension HookMacro: MemberAttributeMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingAttributesFor member: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AttributeSyntax] {
        guard declaration.is(StructDeclSyntax.self),
              let varDecl = member.as(VariableDeclSyntax.self),
              isStoredVarWithTypeAnnotation(varDecl) else {
            return []
        }
        return [AttributeSyntax(attributeName: IdentifierTypeSyntax(name: .identifier("_HookAccessor")))]
    }
}

// MARK: - ExtensionMacro（DynamicProperty 準拠）

extension HookMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard declaration.is(StructDeclSyntax.self) else {
            return []
        }
        let ext: DeclSyntax = """
            extension \(type.trimmed): DynamicProperty {}
            """
        guard let extDecl = ext.as(ExtensionDeclSyntax.self) else {
            return []
        }
        return [extDecl]
    }
}

// MARK: - ヘルパー

private struct StoredVarInfo {
    let name: String
    let type: String
    let defaultValue: String?
    /// プロパティ個別のアクセス修飾子（private, fileprivate 等）
    let accessModifier: String?

    /// 外部から非公開かどうか（private / fileprivate）
    var isPrivateAccess: Bool {
        accessModifier == "private" || accessModifier == "fileprivate"
    }

    /// Storage プロパティに適用するアクセス修飾子を返す
    /// - private → fileprivate（ネストされた型なのでスコープが変わるため）
    /// - fileprivate → fileprivate
    /// - public/open/internal → そのまま（明示的な意図を尊重）
    /// - 修飾子なし → struct のアクセスレベルに従う
    func storageAccessModifier(structAccessLevel: String) -> String {
        switch accessModifier {
        case "private":
            return "fileprivate "
        case let modifier?:
            return modifier + " "
        default:
            return structAccessLevel
        }
    }
}

/// stored var を抽出する（型注釈必須）
private func extractStoredVars(
    from declaration: some DeclGroupSyntax,
    in context: some MacroExpansionContext
) -> [StoredVarInfo] {
    declaration.memberBlock.members.compactMap { member -> StoredVarInfo? in
        guard let varDecl = member.decl.as(VariableDeclSyntax.self),
              isStoredVar(varDecl) else {
            return nil
        }

        guard let binding = varDecl.bindings.first,
              let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
            return nil
        }

        guard let typeAnnotation = binding.typeAnnotation else {
            // 型注釈なしの stored var はエラー
            context.diagnose(Diagnostic(
                node: varDecl,
                message: HookDiagnosticMessage.missingTypeAnnotation(name: pattern.identifier.trimmedDescription)
            ))
            return nil
        }

        let name = pattern.identifier.trimmedDescription
        let type = typeAnnotation.type.trimmedDescription
        let defaultValue = binding.initializer?.value.trimmedDescription

        // アクセス修飾子を抽出（private, fileprivate 等）
        let accessModifier: String? = varDecl.modifiers.lazy
            .map { $0.name.tokenKind }
            .compactMap { tokenKind -> String? in
                switch tokenKind {
                case .keyword(.private): return "private"
                case .keyword(.fileprivate): return "fileprivate"
                case .keyword(.internal): return "internal"
                case .keyword(.public): return "public"
                case .keyword(.open): return "open"
                default: return nil
                }
            }
            .first

        // private/fileprivate なプロパティにはデフォルト値が必須
        if (accessModifier == "private" || accessModifier == "fileprivate") && defaultValue == nil {
            context.diagnose(Diagnostic(
                node: varDecl,
                message: HookDiagnosticMessage.privatePropertyRequiresDefault(name: name)
            ))
            return nil
        }

        return StoredVarInfo(name: name, type: type, defaultValue: defaultValue, accessModifier: accessModifier)
    }
}

/// @State 付きプロパティがあれば警告を出す
private func warnStateProperties(
    in declaration: some DeclGroupSyntax,
    context: some MacroExpansionContext
) {
    for member in declaration.memberBlock.members {
        guard let varDecl = member.decl.as(VariableDeclSyntax.self) else { continue }
        for attr in varDecl.attributes {
            if case let .attribute(a) = attr,
               let identType = a.attributeName.as(IdentifierTypeSyntax.self),
               identType.name.trimmedDescription == "State" {
                if let binding = varDecl.bindings.first,
                   let pattern = binding.pattern.as(IdentifierPatternSyntax.self) {
                    context.diagnose(Diagnostic(
                        node: varDecl,
                        message: HookDiagnosticMessage.statePropertyInHook(
                            name: pattern.identifier.trimmedDescription
                        )
                    ))
                }
            }
        }
    }
}

/// stored var かどうか判定する（型注釈の有無は問わない）
private func isStoredVar(_ varDecl: VariableDeclSyntax) -> Bool {
    // let は除外（sub-hook や定数）
    guard varDecl.bindingSpecifier.tokenKind == .keyword(.var) else {
        return false
    }

    guard let binding = varDecl.bindings.first else {
        return false
    }

    // accessor block があれば computed property
    if binding.accessorBlock != nil {
        return false
    }

    // @HookState が付いている場合のみ stored var として扱う
    for attr in varDecl.attributes {
        if case let .attribute(a) = attr,
           let identType = a.attributeName.as(IdentifierTypeSyntax.self),
           identType.name.trimmedDescription == "HookState" {
            return true
        }
    }

    return false
}

/// stored var かつ型注釈ありかどうか判定する
private func isStoredVarWithTypeAnnotation(_ varDecl: VariableDeclSyntax) -> Bool {
    guard isStoredVar(varDecl),
          let binding = varDecl.bindings.first,
          binding.typeAnnotation != nil else {
        return false
    }
    return true
}

// MARK: - Diagnostics

private struct DiagnosticsError: Error, CustomStringConvertible {
    let message: String
    var description: String { message }
}

private struct HookDiagnosticMessage: DiagnosticMessage {
    let message: String
    let diagnosticID: MessageID
    let severity: DiagnosticSeverity

    static func statePropertyInHook(name: String) -> Self {
        HookDiagnosticMessage(
            message: "@State should not be used inside @Hook. Use @HookState on '\(name)' instead.",
            diagnosticID: MessageID(domain: "SwiftHooksMacrosPlugin", id: "statePropertyInHook"),
            severity: .warning
        )
    }

    static func privatePropertyRequiresDefault(name: String) -> Self {
        HookDiagnosticMessage(
            message: "Private @HookState property '\(name)' requires a default value.",
            diagnosticID: MessageID(domain: "SwiftHooksMacrosPlugin", id: "privatePropertyRequiresDefault"),
            severity: .error
        )
    }

    static func missingTypeAnnotation(name: String) -> Self {
        HookDiagnosticMessage(
            message: "@Hook requires type annotation on stored property '\(name)'. Write 'var \(name): Type = ...' instead.",
            diagnosticID: MessageID(domain: "SwiftHooksMacrosPlugin", id: "missingTypeAnnotation"),
            severity: .error
        )
    }
}
