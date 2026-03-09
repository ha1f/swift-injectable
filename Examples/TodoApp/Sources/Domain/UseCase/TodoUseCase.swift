import Foundation

/// TodoUseCaseProtocolの実装
@MainActor
public struct TodoUseCase: TodoUseCaseProtocol {
    private let repository: any TodoRepositoryProtocol
    private let logger: any LoggerProtocol

    public init(repository: any TodoRepositoryProtocol, logger: any LoggerProtocol) {
        self.repository = repository
        self.logger = logger
    }

    public var todos: [Todo] {
        repository.todos
    }

    public func fetchAll() async throws {
        logger.log("Todo一覧を取得")
        try await repository.fetchAll()
    }

    public func add(title: String) async throws {
        let todo = Todo(title: title)
        try await repository.add(todo)
        logger.log("Todoを追加: \(title)")
    }

    public func toggleCompletion(_ todo: Todo) async throws {
        var updated = todo
        updated.isCompleted.toggle()
        try await repository.update(updated)
        logger.log("Todoの完了状態を変更: \(todo.title) → \(updated.isCompleted)")
    }

    public func delete(id: UUID) async throws {
        try await repository.delete(id: id)
        logger.log("Todoを削除: \(id)")
    }
}
