import SwiftSyntax
import SwiftSyntaxMacros

public struct InjectableMacro {}

// MARK: - MemberMacro（Dependencies struct + init 生成）

extension InjectableMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard declaration.is(ClassDeclSyntax.self) else {
            throw DiagnosticsError(message: "@Injectable はクラスにのみ適用できます")
        }

        let injectProperties = extractInjectProperties(from: declaration)
        let extraProperties = extractExtraProperties(from: declaration)

        var members: [DeclSyntax] = []

        // ① Dependencies struct（@Inject プロパティがある場合のみ）
        if !injectProperties.isEmpty {
            let envProperties = injectProperties.map { prop in
                "    @Environment(\\.\(prop.name)) var \(prop.name): \(prop.type)"
            }.joined(separator: "\n")

            let className = declaration.as(ClassDeclSyntax.self)!.name.trimmedDescription

            let depsStruct: DeclSyntax = """
                struct Dependencies: DependenciesProtocol {
                    typealias Target = \(raw: className)
                \(raw: envProperties)
                    init() {}
                    func resolve() -> \(raw: className).Dependencies { self }
                }
                """
            members.append(depsStruct)
        }

        // ② memberwise init（テスト用 / 通常のコンストラクタ注入）
        let allProperties = injectProperties + extraProperties
        if !allProperties.isEmpty {
            let params = allProperties.map { "\($0.name): \($0.type)" }.joined(separator: ", ")
            let assignments = allProperties.map { "self.\($0.name) = \($0.name)" }.joined(separator: "\n    ")

            let memberwiseInit: DeclSyntax = """
                init(\(raw: params)) {
                    \(raw: assignments)
                }
                """
            members.append(memberwiseInit)
        }

        // ③ init(deps:)（追加パラメータなしの場合のみ、AutoInjectable用）
        if !injectProperties.isEmpty && extraProperties.isEmpty {
            let depsAssignments = injectProperties.map { "self.\($0.name) = deps.\($0.name)" }.joined(separator: "\n    ")

            let depsInit: DeclSyntax = """
                init(deps: Dependencies) {
                    \(raw: depsAssignments)
                }
                """
            members.append(depsInit)
        }

        return members
    }
}

// MARK: - ExtensionMacro（Injectable 準拠）

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

        let injectProperties = extractInjectProperties(from: declaration)
        guard !injectProperties.isEmpty else {
            return []
        }

        let extraProperties = extractExtraProperties(from: declaration)

        var extensions: [ExtensionDeclSyntax] = []

        // Injectable 準拠（常に生成）
        let injectableExt: DeclSyntax = """
            extension \(type.trimmed): Injectable {}
            """
        if let ext = injectableExt.as(ExtensionDeclSyntax.self) {
            extensions.append(ext)
        }

        // AutoInjectable 準拠（追加パラメータなしの場合のみ）
        if extraProperties.isEmpty {
            let autoExt: DeclSyntax = """
                extension \(type.trimmed): AutoInjectable {}
                """
            if let ext = autoExt.as(ExtensionDeclSyntax.self) {
                extensions.append(ext)
            }
        }

        return extensions
    }
}

// MARK: - ヘルパー

private struct InjectProperty {
    let name: String
    let type: String
}

/// @Inject が付いた let stored property を抽出する（依存）
private func extractInjectProperties(from declaration: some DeclGroupSyntax) -> [InjectProperty] {
    declaration.memberBlock.members.compactMap { member -> InjectProperty? in
        guard let varDecl = member.decl.as(VariableDeclSyntax.self) else {
            return nil
        }

        guard varDecl.bindingSpecifier.tokenKind == .keyword(.let) else {
            return nil
        }

        let hasInject = varDecl.attributes.contains { attr in
            guard case .attribute(let attribute) = attr else { return false }
            return attribute.attributeName.trimmedDescription == "Dependency"
        }
        guard hasInject else {
            return nil
        }

        guard let binding = varDecl.bindings.first,
              let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
              let typeAnnotation = binding.typeAnnotation
        else {
            return nil
        }

        let name = pattern.identifier.trimmedDescription
        let type = typeAnnotation.type.trimmedDescription

        return InjectProperty(name: name, type: type)
    }
}

/// @Inject なし・初期値なしの let stored property を抽出する（カスタムパラメータ）
private func extractExtraProperties(from declaration: some DeclGroupSyntax) -> [InjectProperty] {
    declaration.memberBlock.members.compactMap { member -> InjectProperty? in
        guard let varDecl = member.decl.as(VariableDeclSyntax.self) else {
            return nil
        }

        guard varDecl.bindingSpecifier.tokenKind == .keyword(.let) else {
            return nil
        }

        let hasInject = varDecl.attributes.contains { attr in
            guard case .attribute(let attribute) = attr else { return false }
            return attribute.attributeName.trimmedDescription == "Dependency"
        }
        guard !hasInject else {
            return nil
        }

        guard let binding = varDecl.bindings.first,
              let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
              let typeAnnotation = binding.typeAnnotation
        else {
            return nil
        }

        guard binding.initializer == nil else {
            return nil
        }

        guard binding.accessorBlock == nil else {
            return nil
        }

        let name = pattern.identifier.trimmedDescription
        let type = typeAnnotation.type.trimmedDescription

        return InjectProperty(name: name, type: type)
    }
}

// MARK: - エラー

private struct DiagnosticsError: Error, CustomStringConvertible {
    let message: String
    var description: String { message }
}
