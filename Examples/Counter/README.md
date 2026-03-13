# Counter

## 狙い

**SwiftHooksの基本**を示す最小のサンプル。
DIは使わず、`@Hook`マクロによる状態管理とhook合成だけに集中している。

## Architecture

```
Sources/
├── Feature/CounterFeature/    # @Hook を使ったカウンター機能
└── App/                       # SwiftUI App エントリーポイント
Tests/
└── CounterFeatureTests/       # Hook テスト
```

## What This Example Demonstrates

- `@Hook` — 状態管理（count）とアクション（increment / decrement / reset）
- Hook合成 — `UseCounterView` が `UseCounter` を内包し、表示ロジックを追加
- `binding` — `@Hook` が生成する Binding でViewと連携

## Running

```bash
swift build
swift test
```
