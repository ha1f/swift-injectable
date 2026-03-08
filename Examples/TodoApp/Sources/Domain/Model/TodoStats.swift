/// Todoの統計情報
public struct TodoStats: Equatable, Sendable {
    public let total: Int
    public let active: Int
    public let completed: Int

    public init(total: Int, active: Int, completed: Int) {
        self.total = total
        self.active = active
        self.completed = completed
    }
}
