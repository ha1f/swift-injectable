import Domain
import SwiftHooksQuery

/// Todoリストのクエリキー
enum TodosQueryKey: QueryKey {
    typealias Value = [Todo]
}

extension QueryCache {
    /// Todoリストのクエリエントリ
    public var todos: QueryEntry<[Todo]> {
        entry(for: TodosQueryKey.self)
    }
}
