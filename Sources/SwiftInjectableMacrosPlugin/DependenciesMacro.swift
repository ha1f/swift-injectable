import SwiftSyntax
import SwiftSyntaxMacros

/// @Dependencies マクロ。DI container の lazy getter, backing storage, protocol を自動生成する。
public struct DependenciesMacro {}

// MARK: - MemberMacro（backing storage + lazy getter + init）

extension DependenciesMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard declaration.is(ClassDeclSyntax.self) else {
            throw DiagnosticsError(message: "@Dependencies は class にのみ適用できます")
        }

        let factories = extractFactoryFunctions(from: declaration)
        guard !factories.isEmpty else {
            return []
        }

        var members: [DeclSyntax] = []

        // backing storage + lazy getter
        for f in factories {
            let storage: DeclSyntax = "private var _\(raw: f.propertyName): (\(raw: f.type))?"

            let getter: DeclSyntax = """
                var \(raw: f.propertyName): \(raw: f.type) {
                    if let v = _\(raw: f.propertyName) { return v }
                    let v = \(raw: f.funcName)()
                    _\(raw: f.propertyName) = v
                    return v
                }
                """

            members.append(storage)
            members.append(getter)
        }

        // init（全部 optional、テスト用）
        let params = factories.map {
            "\($0.propertyName): (\($0.type))? = nil"
        }.joined(separator: ", ")
        let assignments = factories.map {
            "self._\($0.propertyName) = \($0.propertyName)"
        }.joined(separator: "\n    ")

        let initDecl: DeclSyntax = """
            init(\(raw: params)) {
                \(raw: assignments)
            }
            """
        members.append(initDecl)

        return members
    }
}

// MARK: - PeerMacro（Protocol + conformance 生成）

extension DependenciesMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let classDecl = declaration.as(ClassDeclSyntax.self) else {
            return []
        }

        let className = classDecl.name.trimmedDescription
        let factories = extractFactoryFunctions(from: classDecl)
        guard !factories.isEmpty else {
            return []
        }

        let protocolMembers = factories.map {
            "    var \($0.propertyName): \($0.type) { get }"
        }.joined(separator: "\n")

        let protocolDecl: DeclSyntax = """
            protocol \(raw: className)Protocol {
            \(raw: protocolMembers)
            }
            """

        return [protocolDecl]
    }
}

// MARK: - ヘルパー

private struct FactoryFunction {
    let funcName: String
    let propertyName: String
    let type: String
}

/// `create*()` パターンの関数を抽出し、プロパティ名を導出する
private func extractFactoryFunctions(from declaration: some DeclGroupSyntax) -> [FactoryFunction] {
    declaration.memberBlock.members.compactMap { member -> FactoryFunction? in
        guard let funcDecl = member.decl.as(FunctionDeclSyntax.self) else {
            return nil
        }

        // 引数なし
        guard funcDecl.signature.parameterClause.parameters.isEmpty else {
            return nil
        }

        // 戻り値あり
        guard let returnType = funcDecl.signature.returnClause?.type else {
            return nil
        }

        let funcName = funcDecl.name.trimmedDescription

        // create* プレフィックスからプロパティ名を導出
        guard funcName.hasPrefix("create"),
              funcName.count > "create".count else {
            return nil
        }

        let suffix = String(funcName.dropFirst("create".count))
        let propertyName = suffix.prefix(1).lowercased() + suffix.dropFirst()

        return FactoryFunction(
            funcName: funcName,
            propertyName: propertyName,
            type: returnType.trimmedDescription
        )
    }
}

private struct DiagnosticsError: Error, CustomStringConvertible {
    let message: String
    var description: String { message }
}
