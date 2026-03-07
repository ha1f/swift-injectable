import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

/// @Provider マクロ。@Provide(as:) が付いたプロパティから registerAll を自動生成する。
public struct ProviderMacro {}

/// @Provide マクロ。マーカーとして機能し、コード生成は行わない。
public struct ProvideMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        []
    }
}

// MARK: - MemberMacro（registerAll 生成）

extension ProviderMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard declaration.is(ClassDeclSyntax.self) else {
            throw DiagnosticsError(message: "@Provider can only be applied to classes")
        }

        let properties = extractProvidedProperties(from: declaration)

        var members: [DeclSyntax] = []

        // registerAll(in:)
        if properties.isEmpty {
            let registerAllDecl: DeclSyntax = """
                func registerAll(in store: inout InjectionStore) {}
                """
            members.append(registerAllDecl)
        } else {
            let registrations = properties.map {
                "    store.register(\($0.name), for: \($0.interfaceType).self)"
            }.joined(separator: "\n")

            let registerAllDecl: DeclSyntax = """
                func registerAll(in store: inout InjectionStore) {
                \(raw: registrations)
                }
                """
            members.append(registerAllDecl)
        }

        return members
    }
}

// MARK: - ExtensionMacro（DependencyProvider 準拠）

extension ProviderMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard declaration.is(ClassDeclSyntax.self) else {
            return []
        }
        let ext: DeclSyntax = """
            extension \(type.trimmed): DependencyProvider {}
            """
        guard let extDecl = ext.as(ExtensionDeclSyntax.self) else {
            return []
        }
        return [extDecl]
    }
}

// MARK: - ヘルパー

private struct ProvidedProperty {
    let name: String
    let interfaceType: String
}

/// `@Provide(as: Type.self)` が付いたプロパティを抽出する
private func extractProvidedProperties(from declaration: some DeclGroupSyntax) -> [ProvidedProperty] {
    declaration.memberBlock.members.compactMap { member -> ProvidedProperty? in
        guard let varDecl = member.decl.as(VariableDeclSyntax.self) else {
            return nil
        }

        // @Provide(as: ...) 属性を探す
        guard let provideAttr = varDecl.attributes.first(where: { attr in
            guard case let .attribute(a) = attr,
                  let identType = a.attributeName.as(IdentifierTypeSyntax.self) else {
                return false
            }
            return identType.name.trimmedDescription == "Provide"
        }) else {
            return nil
        }

        // プロパティ名を取得
        guard let binding = varDecl.bindings.first,
              let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
            return nil
        }

        // @Provide(as: Type.self) から Type を取得
        guard case let .attribute(attr) = provideAttr,
              let arguments = attr.arguments?.as(LabeledExprListSyntax.self),
              let firstArg = arguments.first,
              firstArg.label?.trimmedDescription == "as" else {
            return nil
        }

        // `Type.self` から `Type` を抽出
        let argExpr = firstArg.expression.trimmedDescription
        let interfaceType: String
        if argExpr.hasSuffix(".self") {
            interfaceType = String(argExpr.dropLast(5))
        } else {
            interfaceType = argExpr
        }

        return ProvidedProperty(
            name: pattern.identifier.trimmedDescription,
            interfaceType: interfaceType
        )
    }
}

private struct DiagnosticsError: Error, CustomStringConvertible {
    let message: String
    var description: String { message }
}
