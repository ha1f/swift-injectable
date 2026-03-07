import SwiftSyntax
import SwiftSyntaxMacros

/// @Dependencies マクロ。backing storage、init、ViewModifier 準拠を自動生成する。
public struct DependenciesMacro {}

// MARK: - MemberMacro

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

        let properties = extractComputedProperties(from: declaration)
        guard !properties.isEmpty else {
            return []
        }

        var members: [DeclSyntax] = []

        // backing storage（_name: Type?）
        for prop in properties {
            let storage: DeclSyntax = "var _\(raw: prop.name): (\(raw: prop.type))?"
            members.append(storage)
        }

        // init（全部 optional）
        let params = properties.map { "_ \($0.name): (\($0.type))? = nil" }.joined(separator: ", ")
        let assignments = properties.map { "self._\($0.name) = \($0.name)" }.joined(separator: "\n    ")

        let initDecl: DeclSyntax = """
            init(\(raw: params)) {
                \(raw: assignments)
            }
            """
        members.append(initDecl)

        // ViewModifier body
        let body: DeclSyntax = """
            func body(content: Content) -> some View {
                content
                    .transformEnvironment(\\.dependenciesStore) { store in
                        store.register(self)
                    }
            }
            """
        members.append(body)

        return members
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

private struct ComputedProperty {
    let name: String
    let type: String
}

/// getter のみの computed property を抽出する
private func extractComputedProperties(from declaration: some DeclGroupSyntax) -> [ComputedProperty] {
    declaration.memberBlock.members.compactMap { member -> ComputedProperty? in
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

        // computed property（accessor block あり）のみ対象
        guard binding.accessorBlock != nil else {
            return nil
        }

        let name = pattern.identifier.trimmedDescription

        // _prefix は backing storage なのでスキップ
        guard !name.hasPrefix("_") else {
            return nil
        }

        return ComputedProperty(
            name: name,
            type: typeAnnotation.type.trimmedDescription
        )
    }
}

private struct DiagnosticsError: Error, CustomStringConvertible {
    let message: String
    var description: String { message }
}
