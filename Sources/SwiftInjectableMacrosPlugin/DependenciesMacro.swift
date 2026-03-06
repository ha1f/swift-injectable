import SwiftSyntax
import SwiftSyntaxMacros

/// @Dependencies マクロ。ViewModifier 準拠（body）を自動生成する。
public struct DependenciesMacro {}

// MARK: - MemberMacro（body 生成）

extension DependenciesMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard declaration.is(StructDeclSyntax.self) else {
            throw DiagnosticsError(message: "@Dependencies は struct にのみ適用できます")
        }

        let properties = extractStoredProperties(from: declaration)
        guard !properties.isEmpty else {
            return []
        }

        let body: DeclSyntax = """
            func body(content: Content) -> some View {
                content
                    .transformEnvironment(\\.dependenciesStore) { store in
                        store.register(self)
                    }
            }
            """

        return [body]
    }
}

// MARK: - ExtensionMacro（ViewModifier 準拠）

extension DependenciesMacro: ExtensionMacro {
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

        let extensionDecl: DeclSyntax = """
            extension \(type.trimmed): ViewModifier {}
            """

        guard let ext = extensionDecl.as(ExtensionDeclSyntax.self) else {
            return []
        }
        return [ext]
    }
}

// MARK: - ヘルパー

private struct StoredProperty {
    let name: String
    let type: String
}

private func extractStoredProperties(from declaration: some DeclGroupSyntax) -> [StoredProperty] {
    declaration.memberBlock.members.compactMap { member -> StoredProperty? in
        guard let varDecl = member.decl.as(VariableDeclSyntax.self) else {
            return nil
        }

        guard varDecl.bindingSpecifier.tokenKind == .keyword(.var) else {
            return nil
        }

        guard let binding = varDecl.bindings.first,
              let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
              let typeAnnotation = binding.typeAnnotation
        else {
            return nil
        }

        guard binding.accessorBlock == nil else {
            return nil
        }

        return StoredProperty(
            name: pattern.identifier.trimmedDescription,
            type: typeAnnotation.type.trimmedDescription
        )
    }
}

private struct DiagnosticsError: Error, CustomStringConvertible {
    let message: String
    var description: String { message }
}
