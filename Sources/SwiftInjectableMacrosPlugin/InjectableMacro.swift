import SwiftSyntax
import SwiftSyntaxMacros

public struct InjectableMacro {}

// MARK: - MemberMacro（init生成）

extension InjectableMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // classのみ許可
        guard declaration.is(ClassDeclSyntax.self) else {
            throw DiagnosticsError(message: "@Injectable はクラスにのみ適用できます")
        }

        let injectProperties = extractInjectProperties(from: declaration)
        let extraProperties = extractExtraProperties(from: declaration)

        // ① Container 用 init（本番・auto-resolve 用）
        let containerInjectAssignments = injectProperties.map { prop in
            "self._\(prop.name) = Inject(container.resolve((\(prop.type)).self))"
        }
        let containerExtraAssignments = extraProperties.map { prop in
            "self.\(prop.name) = \(prop.name)"
        }
        let containerBody = (containerInjectAssignments + containerExtraAssignments)
            .joined(separator: "\n    ")
        let extraParams = extraProperties.map { "\($0.name): \($0.type)" }
        let containerParams = (["container: Container"] + extraParams).joined(separator: ", ")

        let containerInit: DeclSyntax = """
            init(\(raw: containerParams)) {
                \(raw: containerBody)
            }
            """

        // ② 直接注入 init（テスト用）— @Inject プロパティがある場合のみ生成
        guard !injectProperties.isEmpty else {
            return [containerInit]
        }

        let directInjectAssignments = injectProperties.map { prop in
            "self._\(prop.name) = Inject(\(prop.name))"
        }
        let directExtraAssignments = extraProperties.map { prop in
            "self.\(prop.name) = \(prop.name)"
        }
        let directBody = (directInjectAssignments + directExtraAssignments)
            .joined(separator: "\n    ")
        let directInjectParams = injectProperties.map { "\($0.name): \($0.type)" }
        let directParams = (directInjectParams + extraParams).joined(separator: ", ")

        let directInit: DeclSyntax = """
            init(\(raw: directParams)) {
                \(raw: directBody)
            }
            """

        return [containerInit, directInit]
    }
}

// MARK: - ExtensionMacro（Injectable準拠）

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

        // 追加引数がある場合は init(container:) と一致しないため準拠を生成しない
        let extraProperties = extractExtraProperties(from: declaration)
        guard extraProperties.isEmpty else {
            return []
        }

        let extensionDecl: DeclSyntax = """
            extension \(type.trimmed): Injectable {}
            """

        guard let ext = extensionDecl.as(ExtensionDeclSyntax.self) else {
            return []
        }
        return [ext]
    }
}

// MARK: - ヘルパー

private struct InjectProperty {
    let name: String
    let type: String
}

/// @Inject なし・デフォルト値なしの stored property を抽出する（追加引数になる）
private func extractExtraProperties(from declaration: some DeclGroupSyntax) -> [InjectProperty] {
    declaration.memberBlock.members.compactMap { member -> InjectProperty? in
        guard let varDecl = member.decl.as(VariableDeclSyntax.self) else {
            return nil
        }

        // @Inject が付いていないことを確認
        let hasInject = varDecl.attributes.contains { attr in
            guard case .attribute(let attribute) = attr else { return false }
            return attribute.attributeName.trimmedDescription == "Inject"
        }
        guard !hasInject else {
            return nil
        }

        // 最初のバインディングから判定
        guard let binding = varDecl.bindings.first,
              let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
              let typeAnnotation = binding.typeAnnotation
        else {
            return nil
        }

        // デフォルト値がある場合はスキップ
        guard binding.initializer == nil else {
            return nil
        }

        // computed property はスキップ（accessor がある場合）
        guard binding.accessorBlock == nil else {
            return nil
        }

        let name = pattern.identifier.trimmedDescription
        let type = typeAnnotation.type.trimmedDescription

        return InjectProperty(name: name, type: type)
    }
}

/// @Inject が付いた var stored property を抽出する
private func extractInjectProperties(from declaration: some DeclGroupSyntax) -> [InjectProperty] {
    declaration.memberBlock.members.compactMap { member -> InjectProperty? in
        guard let varDecl = member.decl.as(VariableDeclSyntax.self) else {
            return nil
        }

        // var であることを確認
        guard varDecl.bindingSpecifier.tokenKind == .keyword(.var) else {
            return nil
        }

        // @Inject 属性が付いているか確認
        let hasInject = varDecl.attributes.contains { attr in
            guard case .attribute(let attribute) = attr else { return false }
            return attribute.attributeName.trimmedDescription == "Inject"
        }
        guard hasInject else {
            return nil
        }

        // 最初のバインディングから名前と型を取得
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

// MARK: - エラー

private struct DiagnosticsError: Error, CustomStringConvertible {
    let message: String
    var description: String { message }
}
