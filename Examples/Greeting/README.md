# Greeting

## 狙い

**SwiftInjectable + SwiftHooks の最小構成**を示す。
DI（依存性注入）の基本パターン — protocol定義 → 実装の注入 → テストでの差し替え — を、
挨拶アプリというシンプルな題材で一通り体験できるようにしている。

## Architecture

```
Sources/
├── Domain/                        # Protocol定義
├── Feature/GreetingFeature/       # @Hook + @Injected を使った挨拶機能
└── App/                           # @Provider コンテナ + エントリーポイント
Tests/
└── GreetingFeatureTests/          # providerを差し替えたhookテスト
```

## What This Example Demonstrates

- `@Provider` / `@Provide(as:)` — 依存コンテナの定義
- `.injectAll()` — ルートViewへの一括注入
- `@Injected` — hookからの依存解決
- `@Hook` — 状態管理と `binding` によるView連携
- `withTestInjection` — テスト時の依存差し替え

## Running

```bash
swift build
swift test
```
