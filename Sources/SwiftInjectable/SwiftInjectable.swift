@_exported import SwiftUI

// MARK: - マクロ宣言

/// DI container に `registerAll` メソッドと `init` を自動生成する。
/// `lazy var` プロパティを読み取り、各依存を `InjectionStore` に個別登録する。
@attached(member, names: named(registerAll), named(init))
@attached(extension, conformances: InjectableContainer)
public macro Injectable() = #externalMacro(
    module: "SwiftInjectableMacrosPlugin",
    type: "InjectableMacro"
)

// MARK: - InjectableContainer プロトコル

/// `@Injectable` を付けたクラスが準拠するプロトコル。
/// `injectAll()` で Environment に全依存を一括登録するために使う。
@MainActor
public protocol InjectableContainer {
    func registerAll(in store: inout InjectionStore)
}

// MARK: - InjectionStore

/// 型ごとに依存を格納する Environment ストレージ。
public struct InjectionStore: @unchecked Sendable {
    private var values: [ObjectIdentifier: Any] = [:]

    public init() {}

    public mutating func register<D>(_ value: D, as type: D.Type) {
        values[ObjectIdentifier(type)] = value
    }

    public func resolve<D>(_ type: D.Type) -> D? {
        values[ObjectIdentifier(type)] as? D
    }
}

private struct InjectionStoreKey: EnvironmentKey {
    static let defaultValue = InjectionStore()
}

extension EnvironmentValues {
    public var injectionStore: InjectionStore {
        get { self[InjectionStoreKey.self] }
        set { self[InjectionStoreKey.self] = newValue }
    }
}

// MARK: - @Inject property wrapper

/// Environment から依存を型で取得する property wrapper。
@propertyWrapper
public struct Inject<D>: DynamicProperty {
    @Environment(\.injectionStore) private var store

    public var wrappedValue: D {
        guard let value = store.resolve(D.self) else {
            fatalError("\(D.self) が見つかりません。.inject() または .injectAll() を忘れていませんか？")
        }
        return value
    }

    public init() {}
}

// MARK: - View extension

extension View {
    /// 単一の依存を型をキーにして Environment に注入する。
    public func inject<D>(_ value: D, as type: D.Type) -> some View {
        self.transformEnvironment(\.injectionStore) { store in
            store.register(value, as: type)
        }
    }

    /// `@Injectable` container の全依存を一括で Environment に注入する。
    @MainActor
    public func injectAll(_ container: some InjectableContainer) -> some View {
        self.transformEnvironment(\.injectionStore) { store in
            MainActor.assumeIsolated {
                container.registerAll(in: &store)
            }
        }
    }
}
