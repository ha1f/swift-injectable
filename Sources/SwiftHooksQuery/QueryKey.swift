/// クエリキャッシュのキーを定義するプロトコル
/// `SharedStateKey` と同じパターンで使用する
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
