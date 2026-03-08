# TodoApp

swift-injectable の高度な使用パターンを示すサンプルアプリです。

## アーキテクチャ

Clean Architecture に基づいた構成です。

```
Sources/
├── Domain/          # モデル、プロトコル、ユースケース
├── Data/            # InMemoryTodoRepository（リポジトリ実装）
├── Infrastructure/  # ConsoleLogger（ログ実装）
├── Presentation/    # Hooks（状態管理）+ Views（UI）
└── App/             # エントリポイントと依存コンテナ
```

## 主な機能

- **CRUD操作**: Todoの作成・読取・更新（完了トグル）・削除
- **フィルタリング**: すべて / 未完了 / 完了 のフィルター切り替え
- **統計表示**: 完了率や件数の統計

## デモするパターン

### @Hook マクロ
- `UseTodoList` — 複数の `@Injected` 依存を持つhook
- `UseTodoForm` — フォーム入力バリデーション
- `UseTodoFilter` — DI不要な純粋ロジックhook
- `UseTodoStats` — `UseTodoList` を合成して統計を導出するhook

### @Provider / @Provide マクロ
- `AppDependencies` — 全依存を一括登録するコンテナ

### @Injected プロパティラッパー
- Hookから `TodoUseCaseProtocol` 等のプロトコルを解決

### withTestInjection
- TaskLocalベースのテスト用DI（`.serialized` 不要で並列テスト可能）
- 楽観的更新のロールバック検証
- Hook合成（UseTodoStats ← UseTodoList）のテスト

## ビルド・テスト

```bash
cd Examples/TodoApp
swift build
swift test
```
