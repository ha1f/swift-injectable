@_exported import SwiftUI

// MARK: - マクロ宣言

/// ViewModifier 準拠（body）を自動生成する。
@attached(member, names: named(body), named(init), arbitrary)
@attached(extension, conformances: ViewModifier)
public macro Dependencies() = #externalMacro(
    module: "SwiftInjectableMacrosPlugin",
    type: "DependenciesMacro"
)

// MARK: - Dependencies ストレージ

/// 型ごとに Dependencies を格納する環境ストレージ
public struct DependenciesStore: @unchecked Sendable {
    private var values: [ObjectIdentifier: Any] = [:]

    public init() {}

    public mutating func register<D>(_ deps: D) {
        values[ObjectIdentifier(D.self)] = deps
    }

    public func resolve<D>(_ type: D.Type) -> D? {
        values[ObjectIdentifier(D.self)] as? D
    }
}

private struct DependenciesStoreKey: EnvironmentKey {
    static let defaultValue = DependenciesStore()
}

extension EnvironmentValues {
    public var dependenciesStore: DependenciesStore {
        get { self[DependenciesStoreKey.self] }
        set { self[DependenciesStoreKey.self] = newValue }
    }
}

// MARK: - @Deps property wrapper

/// @Dependencies struct から依存を取得する property wrapper
@propertyWrapper
public struct Deps<D>: DynamicProperty {
    @Environment(\.dependenciesStore) private var store

    public var wrappedValue: D {
        guard let deps = store.resolve(D.self) else {
            fatalError("\(D.self) が見つかりません。.inject() を忘れていませんか？")
        }
        return deps
    }

    public init() {}
}

// MARK: - View extension

extension View {
    /// @Dependencies struct を使って依存を一括注入する。
    public func inject(_ modifier: some ViewModifier) -> some View {
        self.modifier(modifier)
    }
}
