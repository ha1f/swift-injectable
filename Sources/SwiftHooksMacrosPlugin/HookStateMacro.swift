import SwiftSyntax
import SwiftSyntaxMacros

/// `@HookState` のマーカーマクロ実装。コード生成は行わない。
/// `@Hook` マクロが `@HookState` の存在を検出して Storage への移動を決定する。
public struct HookStateMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        []
    }
}
