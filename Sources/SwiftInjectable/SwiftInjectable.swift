import SwiftUI

// MARK: - マクロ宣言

/// DI container に `registerAll` メソッドと `init` を自動生成する。
/// `@Provide(as:)` が付いたプロパティを読み取り、各依存を `InjectionStore` に個別登録する。
@attached(member, names: named(registerAll))
@attached(extension, conformances: InjectableContainer)
public macro Injectable() = #externalMacro(
    module: "SwiftInjectableMacrosPlugin",
    type: "InjectableMacro"
)

/// `@Injectable` クラス内のプロパティに付けて、登録するインターフェース型を指定する。
@attached(peer)
public macro Provide<T>(as type: T.Type) = #externalMacro(
    module: "SwiftInjectableMacrosPlugin",
    type: "ProvideMacro"
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

// MARK: - テスト用オーバーライド

/// テスト時に `@Injected` の解決元を上書きするためのストア。
/// `withTestInjection` 経由で使う。
@MainActor
public enum InjectionOverride {
    public static var current: InjectionStore?
}

/// テスト内で `@Injected` が解決する依存をオーバーライドする。
/// SwiftUI の Environment を使わずに DynamicProperty をテストできる。
@MainActor
public func withTestInjection(
    configure: (inout InjectionStore) -> Void,
    perform: @MainActor () async throws -> Void
) async rethrows {
    var store = InjectionStore()
    configure(&store)
    InjectionOverride.current = store
    defer { InjectionOverride.current = nil }
    try await perform()
}

// MARK: - @Injected property wrapper

/// Environment から依存を型で取得する property wrapper。
/// テスト時は `InjectionOverride` が設定されていればそちらを優先する。
/// 使い方: `@Injected var logger: any LoggerProtocol`
@propertyWrapper
public struct Injected<D>: DynamicProperty {
    @Environment(\.injectionStore) private var store

    public var wrappedValue: D {
        // テスト用オーバーライドを優先
        if let override = MainActor.assumeIsolated({ InjectionOverride.current }),
           let value = override.resolve(D.self) {
            return value
        }
        guard let value = store.resolve(D.self) else {
            fatalError("\(D.self) not found. Did you forget to call .inject() or .injectAll()?")
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
