import Observation
import SwiftInjectable
import SwiftUI

// MARK: - QueryEntry

/// クエリ結果を保持する @Observable エントリ
/// data / isLoading / error の三状態を管理し、SwiftUI のビュー更新を駆動する
@Observable
@MainActor
public final class QueryEntry<Value: Sendable>: @unchecked Sendable {
    /// 取得済みデータ
    public var data: Value?
    /// 読み込み中かどうか
    public private(set) var isLoading: Bool = false
    /// 最後に発生したエラー
    public var error: (any Error)?

    init() {}

    func startLoading() {
        isLoading = true
    }

    func succeed(_ value: Value) {
        data = value
        error = nil
        isLoading = false
    }

    func fail(_ error: any Error) {
        self.error = error
        isLoading = false
    }
}

// MARK: - QueryCache

/// クエリ結果のキャッシュストア
/// キーごとに `QueryEntry` を1つ保持し、複数の `UseQuery` 間でデータを共有する
@MainActor
public final class QueryCache: @unchecked Sendable {
    private var entries: [ObjectIdentifier: Any] = [:]

    public nonisolated init() {}

    /// キーに対応する QueryEntry を取得する（なければ作成）
    public func entry<K: QueryKey>(for key: K.Type) -> QueryEntry<K.Value> {
        let id = ObjectIdentifier(key)
        if let existing = entries[id] as? QueryEntry<K.Value> {
            return existing
        }
        let newEntry = QueryEntry<K.Value>()
        entries[id] = newEntry
        return newEntry
    }
}

// MARK: - SwiftUI Environment 統合

@MainActor
private struct QueryCacheEnvironmentKey: EnvironmentKey {
    nonisolated static let defaultValue = QueryCache()
}

extension EnvironmentValues {
    /// クエリキャッシュ
    public var queryCache: QueryCache {
        get { self[QueryCacheEnvironmentKey.self] }
        set { self[QueryCacheEnvironmentKey.self] = newValue }
    }
}

// MARK: - InjectionStore 統合

extension InjectionStore {
    /// クエリキャッシュ
    /// `withTestInjection` 内でキャッシュをセットアップするために使用する
    ///
    /// ```swift
    /// await withTestInjection(configure: { store in
    ///     store.queryCache.todos.data = [Todo(title: "test")]
    /// }) {
    ///     let hook = UseTodosQuery()
    ///     #expect(hook.query.data == [...])
    /// }
    /// ```
    public var queryCache: QueryCache {
        mutating get {
            if let existing = resolve(QueryCache.self) {
                return existing
            }
            let new = QueryCache()
            register(new, for: QueryCache.self)
            return new
        }
        set {
            register(newValue, for: QueryCache.self)
        }
    }
}
