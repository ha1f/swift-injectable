# SwiftUI DI アーキテクチャ候補

## 背景

SwiftUI では `@Environment` の値が `View.init` 時に利用できない。
そのため、ViewModel に依存を注入するには工夫が必要になる。

```swift
struct FeatureView: View {
    @Environment(\.apiClient) var apiClient  // body でしか使えない
    @StateObject var vm: FeatureViewModel    // init で apiClient が必要

    // init 時に apiClient を vm に渡せない
}
```

---

## 他言語の DI 手法

### 主要フレームワークの比較

| 言語/FW | 方式 | 特徴 |
|---|---|---|
| **Java (Spring)** | `@Autowired` constructor | コンストラクタ引数で注入。コンストラクタが1つなら `@Autowired` 省略可 |
| **Kotlin (Hilt/Dagger)** | `@Inject constructor` | コンパイル時にDIコード生成。ランタイムエラーなし |
| **Go** | 関数引数 / struct フィールド | FW不要。`NewService(dep1, dep2)` のように素朴に書く |
| **Rust** | 関数引数 / trait object | FW不要。`impl` ブロックで trait を受け取る |
| **TypeScript (NestJS)** | constructor injection | デコレータ + reflect-metadata でコンストラクタ注入 |
| **Python (FastAPI)** | `Depends()` | 関数引数にデフォルト値として `Depends(get_db)` を書く |
| **.NET (ASP.NET Core)** | constructor injection | DI コンテナが標準搭載。コンストラクタ引数で自動注入 |

### 共通する設計原則

1. **依存は明示的であるべき** — 何に依存しているかコンストラクタを見れば分かる
2. **Service Locator は避ける** — `container.resolve()` を呼ぶ側がコンテナに依存する
3. **コンパイル時に検出できるのが理想** — Dagger/Hilt はコード生成で実現
4. **テスト時は依存を直接渡す** — コンテナ経由でなくコンストラクタ引数で mock を渡す

### Go / Rust の「FW不要」アプローチ

Go と Rust は DI フレームワークをほとんど使わない。

- **Go**: `func NewUserService(repo UserRepository, logger Logger) *UserService`
- **Rust**: `impl UserService { fn new(repo: Box<dyn UserRepository>) -> Self }`

言語自体の機能（インターフェース / trait + コンストラクタ）で十分。
Swift も protocol + init で同じことができるが、SwiftUI の Environment 制約がそれを難しくしている。

### swift-dependencies (Point-Free)

- `DependencyValues` (struct) にすべての依存を集約
- `@Dependency(\.apiClient) var apiClient` で取得（DynamicProperty ベース）
- テスト時は `withDependencies { $0.apiClient = mock }` でオーバーライド
- Task Local を使った依存伝搬（SwiftUI 非依存）

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

- 依存の追加・削除が容易（View 側の変更不要）
- テスト時は直接注入 init で Container 不要

### デメリット

- Container がランタイムで型解決（`fatalError` の可能性）
- Service Locator パターンに該当する
- フレームワーク依存が発生する
- `@Injected` は struct property 保持のため、View 再構築で再 resolve される

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
struct Dependencies {
    var apiClient: any APIClientProtocol
    var logger: any LoggerProtocol
}

extension EnvironmentValues {
    @Entry var dependencies = Dependencies(
        apiClient: LiveAPIClient(),
        logger: ConsoleLogger()
    )
}

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
```

### メリット

- フレームワーク不要（Swift の言語機能のみ）
- 完全に型安全（コンパイル時エラー）
- memberwise init が自動生成される

### デメリット

- ViewModel の遅延生成が必要（`.task` で生成、Optional になる）
- 依存追加時に Dependencies struct と全生成箇所を修正する必要がある
- 依存が多い場合に struct が肥大化する

---

## 候補3: 各依存を個別に Environment に入れる

各依存を個別の EnvironmentKey として登録する。

### 仕組み

- 各プロトコルに対応する EnvironmentKey を定義
- View ツリーの上流で `.environment(\.apiClient, LiveAPIClient())` で設定
- ViewModel は `.task` で遅延生成

### コード例

```swift
extension EnvironmentValues {
    @Entry var apiClient: any APIClientProtocol = LiveAPIClient()
    @Entry var logger: any LoggerProtocol = ConsoleLogger()
}

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
```

### メリット

- フレームワーク不要
- 型安全
- 各依存を個別に差し替え可能（Preview で特定の依存だけ mock）

### デメリット

- EnvironmentKey のボイラープレートが依存の数だけ増える（`@Entry` で軽減）
- ViewModel への依存数が増えると View 側の `@Environment` 宣言が増える
- ViewModel の遅延生成が必要（Optional 問題）

---

## 候補4: @Injected + @State 保持（DynamicProperty + @State）

DynamicProperty 内で Environment を読み、`@State` として ViewModel を保持する。
候補1 の `@Injected` を改善し、VM の寿命を `@State` で管理する。

### 仕組み

- `@Injected` が DynamicProperty に準拠
- `update()` で `@Environment(\.container)` から ViewModel を生成
- `@State` で保持するため、View 再構築でも寿命が維持される
- `@Observable` (iOS 17+) が前提

### コード例

```swift
@propertyWrapper
struct Injected<T: Observable & Injectable>: DynamicProperty {
    @Environment(\.container) private var container
    @State private var object: T?

    var wrappedValue: T { object! }

    mutating func update() {
        if object == nil {
            object = container.resolve(T.self)
        }
    }
}

// View
struct FeatureView: View {
    @Injected var vm: FeatureViewModel

    var body: some View {
        Text(vm.userName)
    }
}

// テスト（直接注入 init を使う）
let vm = FeatureViewModel(apiClient: mock, logger: mock)
```

### メリット

- View 側のコードがシンプル（`@Injected var vm: T` だけ）
- `@State` で保持するため ViewModel の寿命が安定
- `@Observable` と相性が良い
- テスト時は直接注入 init（マクロ生成）を使える

### デメリット

- Container が必要
- `@Observable` (iOS 17+) が前提
- Container のランタイム型解決は候補1と同じ

---

## 候補5: ViewModel を DynamicProperty (struct) にする

ViewModel 自体を struct にして DynamicProperty に準拠させる。

### 仕組み

- ViewModel を struct として定義し、DynamicProperty に準拠
- `@Environment` を ViewModel 内に直接書ける
- SwiftUI が `update()` で Environment を注入する

### コード例

```swift
struct FeatureViewModel: DynamicProperty {
    @Environment(\.apiClient) var apiClient
    @State var userName: String = ""
    @State var isLoading: Bool = false

    func fetch(userId: Int) async {
        let user = try? await apiClient.fetchUser(id: userId)
        userName = user?.name ?? ""
    }
}

struct FeatureView: View {
    var vm = FeatureViewModel()

    var body: some View {
        Text(vm.userName)
            .task { await vm.fetch(userId: 42) }
    }
}
```

### メリット

- フレームワーク完全不要
- Environment ブリッジング問題が根本的に解消
- Optional 不要、遅延生成不要

### デメリット

- `@Observable` / `ObservableObject` が使えない（MVVM パターンと合わない）
- テストが難しい（`@Environment` に依存するため SwiftUI コンテキストが必要）

---

## 不可能な方式

### Dependency struct (DynamicProperty) を class ViewModel に渡す

```swift
struct FeatureDependency: DynamicProperty {
    @Environment(\.apiClient) var apiClient
}

class FeatureViewModel: ObservableObject {
    let dependency: FeatureDependency  // DynamicProperty の接続が切れる
}
```

class に struct をコピーした時点で DynamicProperty の SwiftUI との接続が切れる。
SwiftUI は View の直下の DynamicProperty しか管理しないため、不可能。

---

## 比較表

| | 型安全 | FW不要 | View簡潔 | テスト容易 | VM寿命安定 | MVVM互換 |
|---|---|---|---|---|---|---|
| 1. Container + @Injected | x | x | o | o | x | o |
| 2. Dependencies struct | o | o | x | o | o | o |
| 3. 個別 Environment | o | o | x | o | o | o |
| 4. @Injected + @State | x | x | o | o | o | o |
| 5. DynamicProperty VM | o | o | o | x | o | x |

o = 良い、x = 課題あり
