/// クエリキャッシュのキーを定義するプロトコル
///
/// ```swift
/// private enum TodosQueryKey: QueryKey {
///     typealias Value = [Todo]
/// }
///
/// extension QueryCache {
///     var todos: QueryEntry<[Todo]> {
///         entry(for: TodosQueryKey.self)
///     }
/// }
/// ```
public protocol QueryKey {
    associatedtype Value: Sendable
}
