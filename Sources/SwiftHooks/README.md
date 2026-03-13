# SwiftHooks

`@Hook` マクロでテスト可能な `DynamicProperty` を簡単に作成する。

## 概要

`@Hook` は `@HookState` が付いた stored var を `@Observable` な Storage クラスに移動し、`@SwiftUI.State` で保持する。これにより SwiftUI ビュー内でもユニットテストでも mutation が動作する。

## 使い方

### Hook を定義する

```swift
@Hook
@MainActor
struct UseFetchUser {
    @Injected var userUseCase: any UserUseCaseProtocol
    @Injected var logger: any LoggerProtocol
    @HookState var user: User? = nil
    @HookState var isLoading: Bool = false

    func fetch(userId: Int) async {
        isLoading = true
        defer { isLoading = false }
        do {
            user = try await userUseCase.fetch(userId: userId)
            logger.log("Fetched user: \(user?.name ?? "")")
        } catch {
            logger.log("Error: \(error)")
        }
    }
}
```

### ビューで使う

```swift
struct FeatureView: View {
    var fetchUser = UseFetchUser()

    var body: some View {
        VStack {
            if fetchUser.isLoading {
                ProgressView()
            } else {
                Text(fetchUser.user?.name ?? "No user")
            }
            Button("Fetch") {
                Task { await fetchUser.fetch(userId: 1) }
            }
        }
    }
}
```

## `@Hook` が生成するコード

```swift
@Hook
struct UseCounter {
    @HookState var count: Int = 0
    func increment() { count += 1 }
}
```

展開後:

```swift
struct UseCounter {
    var count: Int {
        get { hookStorage.count }
        nonmutating set { hookStorage.count = newValue }
    }

    func increment() { count += 1 }  // nonmutating set で動作

    @Observable
    final class Storage {
        var count: Int
        init(count: Int) { self.count = count }
    }

    @SwiftUI.State private var hookStorage: Storage

    init(count: Int = 0) {
        _hookStorage = SwiftUI.State(initialValue: Storage(count: count))
    }
}
extension UseCounter: DynamicProperty {}
```

## ルール

| 宣言 | 扱い |
|---|---|
| `@HookState var x: T = value` | `Storage` に移動、computed property に置換 |
| `var x: T = value` (without `@HookState`) | そのまま（サードパーティ property wrapper 等に対応） |
| `var x: T { ... }` (computed) | そのまま |
| `let x = SomeHook()` | そのまま (sub-hook, SwiftUI が管理) |
| `@Injected var x` | そのまま |
| `func ...` | そのまま (`nonmutating set` で mutation 可能) |

## 制約

- **型注釈が必須**: `@HookState` var には `@HookState var count: Int = 0` と書く（`@HookState var count = 0` は不可）。型注釈がない場合はコンパイルエラー
- `@Hook` は struct にのみ適用可能
- `@State` を `@Hook` 内で使うと警告が出る。代わりに `@HookState` を使うこと

## ライフサイクル (`update()`)

`DynamicProperty.update()` を実装すると、ビューの body 評価前に毎回呼ばれる:

```swift
@Hook
@MainActor
struct UseAutoRefresh {
    @Injected var api: any APIClientProtocol
    @HookState var items: [Item] = []
    @HookState var needsRefresh: Bool = true

    mutating func update() {
        guard needsRefresh else { return }
        needsRefresh = false
        Task { items = try await api.fetchItems() }
    }
}
```

> **Note:** `update()` は SwiftUI からのみ呼ばれる。テストでは呼ばれないため、テスト可能な副作用は `fetch()` のような明示的メソッドを使う。

## ステートなし Hook

`@HookState` var がなければ、`Storage` クラスなしで `DynamicProperty` 準拠のみ追加する:

```swift
@Hook
struct UseCounterView {
    let counter = UseCounter()
    var displayText: String { "Count: \(counter.count)" }
}
```

## テスト

`@Hook` は `@Observable` クラス（参照型）に状態を保持するため、SwiftUI ビュー階層外でも mutation が可視。`@Injected` を使う hook は `withTestInjection` でテストする:

```swift
@Test("counter increments")
func counterIncrements() {
    let counter = UseCounter()
    counter.increment()
    #expect(counter.count == 1)
}
```

## マクロ内部動作

1. **Member macro** — `Storage` クラス、`@SwiftUI.State` プロパティ、`init` を生成
2. **Member attribute macro** — 各 `@HookState` var に `@_HookAccessor` を付与
3. **`@_HookAccessor` accessor macro** — `hookStorage` に委譲する `get`/`nonmutating set` を追加し、computed property に変換
4. **`@_HookAccessor` peer macro** — init accessor が必要とするバッキングストアドプロパティを生成
5. **`@HookState` peer macro** — マーカーのみ。`@Hook` が `@HookState` の存在で Storage 移動を判定
6. **Extension macro** — `DynamicProperty` 準拠を追加
