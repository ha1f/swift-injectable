@_exported import SwiftUI

/// ViewModifier 準拠（body）を自動生成する。
@attached(member, names: named(body))
@attached(extension, conformances: ViewModifier)
public macro Dependencies() = #externalMacro(
    module: "SwiftInjectableMacrosPlugin",
    type: "DependenciesMacro"
)

extension View {
    /// @Dependencies struct を使って依存を一括注入する。
    public func inject(_ modifier: some ViewModifier) -> some View {
        self.modifier(modifier)
    }
}
