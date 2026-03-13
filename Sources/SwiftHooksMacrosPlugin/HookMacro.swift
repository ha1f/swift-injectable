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
        let storageProperties = storedVars.map {
            "    \(accessLevel)var \($0.name): \($0.type)"
        }.joined(separator: "\n")

        let initParams = storedVars.map {
            "        \($0.name): \($0.type)"
        }.joined(separator: ",\n")

        let initBody = storedVars.map {
            "            self.\($0.name) = \($0.name)"
        }.joined(separator: "\n")

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

        // init
        let hookInitParams = storedVars.map { sv in
            if let defaultValue = sv.defaultValue {
                return "        \(sv.name): \(sv.type) = \(defaultValue)"
            } else {
                return "        \(sv.name): \(sv.type)"
            }
        }.joined(separator: ",\n")

        // init accessor で初期化されるダミーバッキングストレージの初期化
        let dummyInits = storedVars.map {
            "    self.\($0.name) = \($0.name)"
        }.joined(separator: "\n")

        let storageInitArgs = storedVars.map {
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

        return StoredVarInfo(name: name, type: type, defaultValue: defaultValue)
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

    static func missingTypeAnnotation(name: String) -> Self {
        HookDiagnosticMessage(
            message: "@Hook requires type annotation on stored property '\(name)'. Write 'var \(name): Type = ...' instead.",
            diagnosticID: MessageID(domain: "SwiftHooksMacrosPlugin", id: "missingTypeAnnotation"),
            severity: .error
        )
    }
}
