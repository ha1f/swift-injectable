# TodoApp

swift-injectable の高度な使用パターンを示すサンプルアプリです。

## アーキテクチャ

Feature モジュールごとに分割された構成です。

```
Sources/
├── Domain/                       # モデル、プロトコル（@Observable Repository）
├── Data/                         # InMemoryTodoRepository（リポジトリ実装）
├── Infrastructure/               # ConsoleLogger（ログ実装）
├── Feature/
│   ├── TodoListFeature/          # Todo一覧画面（hooks + views）
│   ├── TodoDetailFeature/        # Todo詳細画面
│   ├── TodoFormFeature/          # Todo入力フォーム
│   └── TodoStatsFeature/         # 統計表示
└── App/                          # エントリポイントと依存コンテナ
Tests/
├── TestSupport/                  # withTodoMocks 等のテスト共通ヘルパー
└── *FeatureTests/                # 各Featureのテスト
```

## 主な機能

- **CRUD操作**: Todoの作成・読取・更新（完了トグル）・削除
- **フィルタリング**: すべて / 未完了 / 完了 のフィルター切り替え
- **統計表示**: 完了率や件数の統計

## デモするパターン

### @Hook マクロ
- `UseTodoRepository` — Repository + Logger のビジネスロジックをまとめたhook
- `UseTodoList` — `UseTodoRepository` を合成し、ローディング/エラー状態を管理するhook
- `UseTodoListView` — `UseTodoList` + `UseTodoFilter` を合成した画面用hook
- `UseTodoForm` — フォーム入力バリデーション
- `UseTodoFilter` — DI不要な純粋ロジックhook
- `UseTodoStats` — `UseTodoList` を合成して統計を導出するhook

### @Provider / @Provide マクロ
- `AppDependencies` — 全依存を一括登録するコンテナ

### @Injected プロパティラッパー
- Hookから `TodoRepositoryProtocol` / `LoggerProtocol` を解決

### withTestInjection + withTodoMocks
- TaskLocalベースのテスト用DI（`.serialized` 不要で並列テスト可能）
- `TestSupport/withTodoMocks` でモック設定を簡潔に記述
- Hook合成（UseTodoStats ← UseTodoList）のテスト

## ビルド・テスト

```bash
cd Examples/TodoApp
swift build
swift test
```
