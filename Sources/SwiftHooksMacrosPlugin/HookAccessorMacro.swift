import SwiftSyntax
import SwiftSyntaxMacros

/// stored var に accessor を追加して computed property に変換する内部マクロ。
public struct HookAccessorMacro {}

// MARK: - AccessorMacro

extension HookAccessorMacro: AccessorMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        guard let varDecl = declaration.as(VariableDeclSyntax.self),
              let binding = varDecl.bindings.first,
              let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
            return []
        }

        let name = pattern.identifier.trimmedDescription
        let backingName = "_hook_backing_\(name)"

        let initAccessor: AccessorDeclSyntax = """
            @storageRestrictions(initializes: \(raw: backingName))
            init(initialValue) {
                \(raw: backingName) = initialValue
            }
            """

        let getAccessor: AccessorDeclSyntax = """
            get {
                hookStorage.\(raw: name)
            }
            """

        let setAccessor: AccessorDeclSyntax = """
            nonmutating set {
                hookStorage.\(raw: name) = newValue
            }
            """

        return [initAccessor, getAccessor, setAccessor]
    }
}

// MARK: - PeerMacro（ダミーバッキングストレージ生成）

extension HookAccessorMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let varDecl = declaration.as(VariableDeclSyntax.self),
              let binding = varDecl.bindings.first,
              let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
            return []
        }

        let name = pattern.identifier.trimmedDescription
        let backingName = "_hook_backing_\(name)"

        guard let typeAnnotation = binding.typeAnnotation else {
            return []
        }

        let type = typeAnnotation.type.trimmedDescription

        // init accessor 用のダミーバッキングストレージ
        let backingDecl: DeclSyntax = """
            private var \(raw: backingName): \(raw: type)
            """

        return [backingDecl]
    }
}
