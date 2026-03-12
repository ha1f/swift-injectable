# SwiftHooksQuery

Apollo Client の `useQuery` に倣ったサーバーステート管理ライブラリ。

## 概要

`QueryCache` がクエリ結果をキーごとに保持し、複数の hook 間でデータを共有する。`UseQuery` は `DynamicProperty` として `@Hook` 内で使い、キャッシュポリシーに従ったデータ取得を行う。

## 使い方

### 1. クエリキーを定義する

```swift
private enum TodosQueryKey: QueryKey {
    typealias Value = [Todo]
}

extension QueryCache {
    var todos: QueryEntry<[Todo]> {
        entry(for: TodosQueryKey.self)
    }
}
```

### 2. カスタムクエリ hook を作る

```swift
@Hook
@MainActor
struct UseTodosQuery {
    @Injected var repository: any TodoRepositoryProtocol
    let query = UseQuery(\.todos, cachePolicy: .cacheFirst)

    func fetch() async {
        await query.fetch {
            try await repository.fetchAll()
        }
    }
}
```

### 3. ビューで使う

```swift
struct TodoListView: View {
    var todosQuery = UseTodosQuery()

    var body: some View {
        Group {
            if todosQuery.query.isLoading {
                ProgressView()
            } else if let todos = todosQuery.query.data {
                List(todos) { todo in Text(todo.title) }
            }
        }
        .task { await todosQuery.fetch() }
    }
}
```

## キャッシュポリシー

| ポリシー | 動作 |
|---|---|
| `.cacheFirst` | キャッシュがあれば返し、なければ fetch（デフォルト） |
| `.networkOnly` | 常に fetch。結果はキャッシュに書き込む |
| `.cacheOnly` | キャッシュのみ参照。fetch しない |
| `.cacheAndNetwork` | キャッシュを先に返し、裏で fetch して更新（stale-while-revalidate） |

## テスト

`withTestInjection` 内で `InjectionStore.queryCache` を使ってキャッシュをセットアップする:

```swift
await withTestInjection(configure: { store in
    store.queryCache.entry(for: TodosQueryKey.self).data = [Todo(title: "test")]
}) {
    let hook = UseTodosQuery()
    #expect(hook.query.data?.count == 1)
}
```

## API リファレンス

| 型 | 説明 |
|---|---|
| `QueryKey` | クエリキャッシュのキーを定義するプロトコル。`associatedtype Value: Sendable` |
| `QueryEntry<Value>` | `@Observable` なクエリ結果コンテナ。`data` / `isLoading` / `error` を管理 |
| `QueryCache` | キーごとに `QueryEntry` を保持するキャッシュストア |
| `QueryCachePolicy` | キャッシュポリシー enum |
| `UseQuery<Value>` | クエリキャッシュにアクセスする `DynamicProperty`。`fetch` / `invalidate` メソッドを提供 |
| `InjectionStore.queryCache` | `withTestInjection` 内でキャッシュにアクセスするためのプロパティ |

## 内部動作

1. **QueryKey** で型安全なキーを定義。`QueryCache` の extension で computed property を生やすことで `KeyPath` でアクセス可能にする
2. **QueryCache** は `ObjectIdentifier` をキーとして `QueryEntry` を管理。同じキーの `UseQuery` は同じ `QueryEntry` インスタンスを共有する
3. **UseQuery** は `@Injected` で `QueryCache` を解決し（テスト時は `withTestInjection` でオーバーライド）、`KeyPath` で `QueryEntry` にアクセスする
4. **QueryEntry** は `@Observable` なので、`data` / `isLoading` / `error` の変更が自動的に SwiftUI のビュー更新を駆動する
