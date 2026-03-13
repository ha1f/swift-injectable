import SwiftUI

// MARK: - マクロ宣言

/// struct を DynamicProperty 準拠の hook に変換する。
/// `@HookState` が付いた stored var を `@Observable` な Storage クラスに移動し、
/// `@SwiftUI.State` で保持することでテストでも動作可能にする。
///
/// `@HookState` を付けた var には型注釈が必須:
/// ```swift
/// @Hook
/// struct UseCounter {
///     @HookState var count: Int = 0
///     func increment() { count += 1 }
/// }
/// ```
@attached(member, names: named(Storage), named(hookStorage), named(binding), named(init), arbitrary)
@attached(memberAttribute)
@attached(extension, conformances: DynamicProperty)
public macro Hook() = #externalMacro(
    module: "SwiftHooksMacrosPlugin",
    type: "HookMacro"
)

/// `@Hook` 内で Storage に移動する stored var を明示するマーカー。
/// `@HookState` が付いた var のみが `@Observable` な Storage クラスに移動され、
/// `@State` で保持される。
///
/// ```swift
/// @Hook
/// struct UseGreeting {
///     @Injected var provider: any GreetingProviderProtocol  // そのまま
///     @HookState var name: String = ""                      // Storage に移動
/// }
/// ```
@attached(peer)
public macro HookState() = #externalMacro(
    module: "SwiftHooksMacrosPlugin",
    type: "HookStateMacro"
)

/// `@Hook` が内部で使用する accessor マクロ。直接使用しない。
@attached(accessor, names: named(init), named(get), named(set))
@attached(peer, names: arbitrary)
public macro _HookAccessor() = #externalMacro(
    module: "SwiftHooksMacrosPlugin",
    type: "HookAccessorMacro"
)
