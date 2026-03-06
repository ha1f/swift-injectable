import SwiftSyntax
import SwiftSyntaxMacros

/// @Dependency マーカー。何も生成しない。@Injectable マクロが読み取る。
public struct DependencyMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        []
    }
}
