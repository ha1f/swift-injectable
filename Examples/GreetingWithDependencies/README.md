# GreetingWithDependencies

## 狙い

**SwiftHooks + swift-dependencies（pointfreeco）の組み合わせ**を示す。
[Greeting](../Greeting) と同じ挨拶アプリを、SwiftInjectable の代わりに
[swift-dependencies](https://github.com/pointfreeco/swift-dependencies) でDIすることで、
両者の違いを比較できるようにしている。

## Greeting との違い

| | Greeting (SwiftInjectable) | GreetingWithDependencies |
|---|---|---|
| DI定義 | `@Provider` + `@Provide(as:)` | `DependencyKey` + `DependencyValues` extension |
| 注入 | `.injectAll()` (SwiftUI Environment) | 自動（`liveValue` がデフォルト） |
| 使用側 | `@Injected var provider` | `@Dependency(\.provider) var provider` |
| テスト | `withTestInjection { store in ... }` | `withDependencies { $0.provider = ... }` |

## Architecture

```
Sources/
├── Domain/                        # Protocol + DependencyKey 定義
├── Feature/GreetingFeature/       # @Hook + @Dependency を使った挨拶機能
└── App/                           # SwiftUI App エントリーポイント
Tests/
└── GreetingFeatureTests/          # withDependencies を使ったテスト
```

## Running

```bash
swift build
swift test
```
