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

        let storedVars = extractStoredVars(from: declaration, in: context)

        // stored var がなければ Storage は生成しない
        if storedVars.isEmpty {
            return []
        }

        // Storage クラス
        let storageProperties = storedVars.map {
            "    var \($0.name): \($0.type)"
        }.joined(separator: "\n")

        let initParams = storedVars.map {
            "        \($0.name): \($0.type)"
        }.joined(separator: ",\n")

        let initBody = storedVars.map {
            "            self.\($0.name) = \($0.name)"
        }.joined(separator: "\n")

        let storageDecl: DeclSyntax = """
            @Observable
            final class Storage {
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

        return [storageDecl, storageProperty, hookInit]
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

    // @Injected などの特定の属性がある場合は除外
    let excludedAttributes: Set<String> = ["Injected", "Environment", "State", "Binding", "ObservedObject", "StateObject"]
    for attr in varDecl.attributes {
        if case let .attribute(a) = attr,
           let identType = a.attributeName.as(IdentifierTypeSyntax.self),
           excludedAttributes.contains(identType.name.trimmedDescription) {
            return false
        }
    }

    return true
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

    static func missingTypeAnnotation(name: String) -> Self {
        HookDiagnosticMessage(
            message: "@Hook requires type annotation on stored property '\(name)'. Write 'var \(name): Type = ...' instead.",
            diagnosticID: MessageID(domain: "SwiftHooksMacrosPlugin", id: "missingTypeAnnotation"),
            severity: .error
        )
    }
}
