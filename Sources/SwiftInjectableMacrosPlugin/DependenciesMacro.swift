import SwiftSyntax
import SwiftSyntaxMacros

/// @Injectable マクロ。lazy var から registerAll と init を自動生成する。
public struct InjectableMacro {}

// MARK: - MemberMacro（registerAll + init 生成）

extension InjectableMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard declaration.is(ClassDeclSyntax.self) else {
            throw DiagnosticsError(message: "@Injectable は class にのみ適用できます")
        }

        let properties = extractLazyProperties(from: declaration)
        guard !properties.isEmpty else {
            return []
        }

        var members: [DeclSyntax] = []

        // registerAll(in:) — 各 lazy var を型キーで登録
        let registrations = properties.map {
            "    store.register(\($0.name), as: (\($0.type)).self)"
        }.joined(separator: "\n")

        let registerAllDecl: DeclSyntax = """
            func registerAll(in store: inout InjectionStore) {
            \(raw: registrations)
            }
            """
        members.append(registerAllDecl)

        // init（全部 optional、テスト用）
        let params = properties.map {
            "\($0.name): (\($0.type))? = nil"
        }.joined(separator: ", ")
        let assignments = properties.map {
            "    if let \($0.name) { self.\($0.name) = \($0.name) }"
        }.joined(separator: "\n")

        let initDecl: DeclSyntax = """
            init(\(raw: params)) {
            \(raw: assignments)
            }
            """
        members.append(initDecl)

        return members
    }
}

// MARK: - ExtensionMacro（InjectableContainer 準拠）

extension InjectableMacro: ExtensionMacro {
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
            extension \(type.trimmed): InjectableContainer {}
            """
        guard let extDecl = ext.as(ExtensionDeclSyntax.self) else {
            return []
        }
        return [extDecl]
    }
}

// MARK: - ヘルパー

private struct LazyProperty {
    let name: String
    let type: String
}

/// `lazy var` プロパティを抽出する
private func extractLazyProperties(from declaration: some DeclGroupSyntax) -> [LazyProperty] {
    declaration.memberBlock.members.compactMap { member -> LazyProperty? in
        guard let varDecl = member.decl.as(VariableDeclSyntax.self) else {
            return nil
        }

        // lazy 修飾子を持つ
        let isLazy = varDecl.modifiers.contains { modifier in
            modifier.name.tokenKind == .keyword(.lazy)
        }
        guard isLazy else {
            return nil
        }

        // バインディングから名前と型を取得
        guard let binding = varDecl.bindings.first,
              let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
              let typeAnnotation = binding.typeAnnotation else {
            return nil
        }

        return LazyProperty(
            name: pattern.identifier.trimmedDescription,
            type: typeAnnotation.type.trimmedDescription
        )
    }
}

private struct DiagnosticsError: Error, CustomStringConvertible {
    let message: String
    var description: String { message }
}
