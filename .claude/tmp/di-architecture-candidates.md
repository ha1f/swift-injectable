# SwiftUI DI アーキテクチャ候補

## 解決したい課題

SwiftUI では `@Environment` の値が `View.init` 時に利用できない。
そのため、ViewModel に依存を注入するのが難しい。

```swift
struct FeatureView: View {
    @Environment(\.apiClient) var apiClient  // body でしか使えない
    @StateObject var vm: FeatureViewModel    // init で apiClient が必要

    // init 時に apiClient を vm に渡せない！
}
```

---

## 候補1: Container + @Injected（現在の実装）

Container クラスに依存を登録し、`@Injected` (DynamicProperty) で解決する。

### 仕組み

- `Container` に singleton/factory で依存を登録
- `@Injected<T>` が DynamicProperty として `update()` で Container から解決
- `@Injectable` マクロが 2つの init を生成（Container用 + 直接注入用）
- SwiftUI Environment 経由で Container を View ツリーに伝搬

### コード例

```swift
// 登録
let container = Container {
    $0.singleton(APIClientProtocol.self) { _ in LiveAPIClient() }
    $0.singleton(LoggerProtocol.self) { _ in ConsoleLogger() }
}

// View
struct FeatureView: View {
    @Injected var vm: FeatureViewModel
    var body: some View { Text(vm.userName) }
}

// ViewModel
@Injectable
class FeatureViewModel {
    @Inject var apiClient: APIClientProtocol
    @Inject var logger: LoggerProtocol
}

// テスト（直接注入 init を使う）
let vm = FeatureViewModel(apiClient: mock, logger: mock)
```

### メリット

- Service Locator パターンで柔軟
- 依存の追加・削除が容易（View 側の変更不要）
- テスト時は直接注入 init で Container 不要

### デメリット

- Container がランタイムで型解決 → 型安全でない（`fatalError` の可能性）
- Service Locator はアンチパターンとされることが多い
- フレームワーク依存が発生する
- `@Injected` は struct property 保持なので、View 再構築で再 resolve される

---

## 候補2: Dependencies 構造体（Plain Struct）

Container の代わりに plain な struct で依存をまとめる。

### 仕組み

- `struct Dependencies` に依存をプロパティとして定義
- Swift が memberwise init を自動生成
- SwiftUI Environment 経由で受け渡し
- ViewModel は `.task` や `onAppear` で遅延生成

### コード例

```swift
// 定義
struct Dependencies {
    var apiClient: any APIClientProtocol
    var logger: any LoggerProtocol
}

// Environment に入れる
extension EnvironmentValues {
    @Entry var dependencies = Dependencies(
        apiClient: LiveAPIClient(),
        logger: ConsoleLogger()
    )
}

// View
struct FeatureView: View {
    @Environment(\.dependencies) var deps
    @State var vm: FeatureViewModel?

    var body: some View {
        Group {
            if let vm { ContentView(vm: vm) }
            else { ProgressView() }
        }
        .task {
            vm = FeatureViewModel(apiClient: deps.apiClient, logger: deps.logger)
        }
    }
}

// テスト（ただの struct init）
let deps = Dependencies(apiClient: mock, logger: mock)
let vm = FeatureViewModel(apiClient: deps.apiClient, logger: deps.logger)
```

### メリット

- フレームワーク不要（Swift の言語機能のみ）
- 完全に型安全（コンパイル時エラー）
- memberwise init が自動生成される
- テストが自然（ただの struct）

### デメリット

- ViewModel の遅延生成が必要（`.task` で生成、Optional になる）
- 依存追加時に Dependencies struct と全生成箇所を修正する必要がある
- 依存が多い場合に struct が肥大化する

---

## 候補3: 各依存を個別に Environment に入れる

Dependencies struct を使わず、各依存を個別の EnvironmentKey として登録する。

### 仕組み

- 各プロトコルに対応する EnvironmentKey を定義
- View ツリーの上流で `.environment(\.apiClient, LiveAPIClient())` で設定
- ViewModel は `.task` で遅延生成

### コード例

```swift
// 各依存を EnvironmentKey として定義
extension EnvironmentValues {
    @Entry var apiClient: any APIClientProtocol = LiveAPIClient()
    @Entry var logger: any LoggerProtocol = ConsoleLogger()
}

// View
struct FeatureView: View {
    @Environment(\.apiClient) var apiClient
    @Environment(\.logger) var logger
    @State var vm: FeatureViewModel?

    var body: some View {
        Group {
            if let vm { ContentView(vm: vm) }
            else { ProgressView() }
        }
        .task {
            vm = FeatureViewModel(apiClient: apiClient, logger: logger)
        }
    }
}

// テスト
let vm = FeatureViewModel(apiClient: mock, logger: mock)
```

### メリット

- フレームワーク完全不要
- 型安全
- 各依存を個別に差し替え可能（Preview で特定の依存だけ mock）
- SwiftUI ネイティブ

### デメリット

- EnvironmentKey のボイラープレートが依存の数だけ増える（`@Entry` で軽減）
- ViewModel への依存数が増えると View 側の `@Environment` 宣言が膨大に
- ViewModel の遅延生成が必要（Optional 問題）
- ViewModel に追加パラメータ（userId 等）がある場合、さらに複雑に

---

## 候補4: LazyStateObject / ResolvedObject（DynamicProperty + StateObject）

DynamicProperty 内で Environment を読み、StateObject としてViewModel を保持する。

### 仕組み

- カスタム property wrapper が DynamicProperty に準拠
- `update()` で `@Environment(\.container)` (or Dependencies) から ViewModel を生成
- `@StateObject` (or `@State`) で保持するため、View 再構築でも寿命が維持される

### コード例

```swift
// Property Wrapper
@propertyWrapper
struct ResolvedObject<T: Observable & Injectable>: DynamicProperty {
    @Environment(\.container) private var container
    @State private var object: T?

    var wrappedValue: T { object! }

    mutating func update() {
        if object == nil {
            object = container.resolve(T.self)
        }
    }
}

// View（シンプル！）
struct FeatureView: View {
    @ResolvedObject var vm: FeatureViewModel

    var body: some View {
        Text(vm.userName)
    }
}

// テスト
let vm = FeatureViewModel(apiClient: mock, logger: mock)
```

### メリット

- View 側のコードが最もシンプル（`@ResolvedObject var vm: T` だけ）
- `@State` で保持するため ViewModel の寿命が安定
- iOS 17+ の `@Observable` と相性が良い
- テスト時は直接注入 init（マクロ生成）を使える

### デメリット

- Container or Dependencies のどちらかが必要（完全フレームワークレスではない）
- `@Observable` (iOS 17+) が前提
- `@StateObject` (Combine ベース) の場合は objectWillChange の購読伝搬が複雑

---

## 候補5: ViewModel を DynamicProperty (struct) にする

ViewModel 自体を struct にして DynamicProperty に準拠させ、Environment を直接読む。

### 仕組み

- ViewModel を struct として定義し、DynamicProperty に準拠
- `@Environment` を ViewModel 内に直接書ける
- SwiftUI が `update()` で Environment を注入してくれる

### コード例

```swift
struct FeatureViewModel: DynamicProperty {
    @Environment(\.apiClient) var apiClient
    @State var userName: String = ""
    @State var isLoading: Bool = false

    func fetch(userId: Int) async {
        // apiClient が使える！
        let user = try? await apiClient.fetchUser(id: userId)
        userName = user?.name ?? ""
    }
}

// View
struct FeatureView: View {
    var vm = FeatureViewModel()

    var body: some View {
        Text(vm.userName)
            .task { await vm.fetch(userId: 42) }
    }
}

// テスト → 困難（@Environment に依存）
```

### メリット

- フレームワーク完全不要
- Environment ブリッジング問題が根本的に解消
- ViewModel がSwiftUI ネイティブ
- Optional 不要、遅延生成不要

### デメリット

- `@Observable` / `ObservableObject` が使えない（MVVM パターンの放棄）
- struct なのでクラスベースの ViewModel と互換性がない
- テストが難しい（`@Environment` に依存するため、SwiftUI コンテキストが必要）
- 既存の MVVM アーキテクチャと合わない

---

## 候補6: Dependency struct を DynamicProperty にして class ViewModel に渡す

DynamicProperty 準拠の依存 struct を作り、class ViewModel のプロパティとして持たせる。

### 仕組み

- `struct Dependency: DynamicProperty` に `@Environment` を集約
- class ViewModel がこの struct を保持

### コード例

```swift
struct FeatureDependency: DynamicProperty {
    @Environment(\.apiClient) var apiClient
    @Environment(\.logger) var logger
}

@MainActor
class FeatureViewModel: ObservableObject {
    let dependency: FeatureDependency
    @Published var userName = ""

    init(dependency: FeatureDependency) {
        self.dependency = dependency
    }
}
```

### 結論: 動かない

class に struct をコピーした時点で DynamicProperty の接続が切れる。
SwiftUI は View の直下の DynamicProperty しか管理しない。
class 内にコピーされた struct の `@Environment` は更新されない。

---

## 比較表

| | 型安全 | FW不要 | View簡潔 | テスト容易 | VM寿命安定 | MVVM互換 |
|---|---|---|---|---|---|---|
| 1. Container + @Injected | x | x | o | o | x | o |
| 2. Dependencies struct | o | o | x | o | o | o |
| 3. 個別 Environment | o | o | x | o | o | o |
| 4. LazyStateObject | x | x | o | o | o | o |
| 5. DynamicProperty VM | o | o | o | x | o | x |
| 6. Dep struct + class VM | - | - | - | - | - | - |

o = 良い、x = 課題あり、- = 不可

---

## 現時点の所感

- **候補1（現在の実装）** は動くが、型安全でないのが弱い
- **候補2, 3** は型安全だが、ViewModel の遅延生成（Optional）が使い勝手を下げる
- **候補4** は候補1の改善版で、View 側が最もシンプル。iOS 17+ なら有力
- **候補5** は革新的だが MVVM を捨てる覚悟が必要
- **候補6** は技術的に不可能
