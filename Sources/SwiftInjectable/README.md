# SwiftInjectable

SwiftUI の `Environment` ベースの型安全な DI コンテナ。

## 概要

- `@Provider` / `@Provide(as:)` マクロで依存コンテナを定義
- `@Injected` プロパティラッパーで依存を解決
- `withTestInjection` で並列安全なテスト用 DI オーバーライド

## 使い方

### 1. プロトコルを定義する

```swift
protocol LoggerProtocol: Sendable {
    func log(_ message: String)
}

protocol APIClientProtocol: Sendable {
    func fetchUser(id: Int) async throws -> User
}
```

### 2. 依存コンテナを作る

`@Provider` をクラスに、`@Provide(as:)` を各プロパティに付ける:

```swift
@MainActor
@Provider
class AppDependencies {
    @Provide(as: (any LoggerProtocol).self)
    lazy var logger = ConsoleLogger()

    @Provide(as: (any APIClientProtocol).self)
    lazy var apiClient = LiveAPIClient()
}
```

`@Provider` が生成するコード:

```swift
class AppDependencies {
    lazy var logger = ConsoleLogger()
    lazy var apiClient = LiveAPIClient()

    func registerAll(in store: inout InjectionStore) {
        store.register(logger, for: (any LoggerProtocol).self)
        store.register(apiClient, for: (any APIClientProtocol).self)
    }
}
extension AppDependencies: DependencyProvider {}
```

### 3. ルートで注入する

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .injectAll(AppDependencies())
        }
    }
}
```

### 4. `@Injected` で解決する

```swift
struct ContentView: View {
    @Injected var logger: any LoggerProtocol

    var body: some View {
        Button("Log") { logger.log("Hello!") }
    }
}
```

### デフォルト値

依存が未登録の場合のフォールバック:

```swift
@Injected(default: ConsoleLogger()) var logger: any LoggerProtocol
```

### 個別注入

コンテナなしで1つずつ注入:

```swift
ContentView()
    .inject(ConsoleLogger(), as: (any LoggerProtocol).self)
```

## テスト

`withTestInjection` で `@Injected` の解決先をオーバーライドする。`TaskLocal` ベースなので並列テストで安全:

```swift
await withTestInjection(configure: { store in
    store.register(mockLogger, for: (any LoggerProtocol).self)
}) {
    let hook = UseFetchUser()
    await hook.fetch(userId: 42)
    #expect(hook.user?.name == "Test User 42")
}
```

## API リファレンス

### マクロ

| マクロ | 説明 |
|---|---|
| `@Provider` | `registerAll(in:)` と `DependencyProvider` 準拠を生成 |
| `@Provide(as: Type.self)` | `@Provider` クラス内のプロパティを指定プロトコル型で登録 |

### プロパティラッパー

| 型 | 説明 |
|---|---|
| `@Injected` | SwiftUI `Environment` から型で依存を解決。テスト時は `InjectionOverride` にフォールバック |

### ビューモディファイア

| モディファイア | 説明 |
|---|---|
| `.injectAll(_:)` | `DependencyProvider` の全依存を Environment に登録 |
| `.inject(_:as:)` | 単一の依存を型で Environment に登録 |

### テストユーティリティ

| API | 説明 |
|---|---|
| `withTestInjection(configure:perform:)` | `perform` の間 `@Injected` の解決をオーバーライド |
| `InjectionStore` | 型キーの依存ストレージ。`register(_:for:)` と `resolve(_:)` |

## 内部動作

1. **Registration** — `.injectAll()` が `registerAll(in:)` を呼び、`InjectionStore` に `ObjectIdentifier` をキーとして各依存を格納
2. **Propagation** — `InjectionStore` が SwiftUI の `Environment` を通じて `transformEnvironment` で伝播
3. **Resolution** — `@Injected` が `@Environment(\.injectionStore)` から依存を型で解決。テスト時は `InjectionOverride.current` を先にチェック
