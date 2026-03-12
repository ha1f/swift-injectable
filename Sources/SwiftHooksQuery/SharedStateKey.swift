/// 共有状態のキーを定義するプロトコル
/// SwiftUI の `EnvironmentKey` と同じパターンで使用する
///
/// ```swift
/// private enum TodosKey: SharedStateKey {
///     static let defaultValue: [Todo] = []
/// }
///
/// extension SharedStateValues {
///     var todos: [Todo] {
///         get { self[TodosKey.self] }
///         set { self[TodosKey.self] = newValue }
///     }
/// }
/// ```
public protocol SharedStateKey {
    associatedtype Value: Sendable
    static var defaultValue: Value { get }
}
