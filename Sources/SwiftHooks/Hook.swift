import SwiftUI

// MARK: - マクロ宣言

/// struct を DynamicProperty 準拠の hook に変換する。
/// stored var を `@Observable` な Storage クラスに移動し、
/// `@SwiftUI.State` で保持することでテストでも動作可能にする。
///
/// stored var には型注釈が必須:
/// ```swift
/// @Hook
/// struct UseCounter {
///     var count: Int = 0
///     func increment() { count += 1 }
/// }
/// ```
@attached(member, names: named(Storage), named(hookStorage), named(init), arbitrary)
@attached(memberAttribute)
@attached(extension, conformances: DynamicProperty)
public macro Hook() = #externalMacro(
    module: "SwiftHooksMacrosPlugin",
    type: "HookMacro"
)

/// `@Hook` が内部で使用する accessor マクロ。直接使用しない。
@attached(accessor, names: named(init), named(get), named(set))
@attached(peer, names: arbitrary)
public macro _HookAccessor() = #externalMacro(
    module: "SwiftHooksMacrosPlugin",
    type: "HookAccessorMacro"
)
