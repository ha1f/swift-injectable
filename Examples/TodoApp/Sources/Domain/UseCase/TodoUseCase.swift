import Foundation

/// TodoUseCaseProtocolの実装
public struct TodoUseCase: TodoUseCaseProtocol {
    private let repository: any TodoRepositoryProtocol
    private let logger: any LoggerProtocol

    public init(repository: any TodoRepositoryProtocol, logger: any LoggerProtocol) {
        self.repository = repository
        self.logger = logger
    }

    public func fetchAll() async throws -> [Todo] {
        logger.log("Todo一覧を取得")
        return try await repository.fetchAll()
    }

    public func add(title: String) async throws -> Todo {
        let todo = Todo(title: title)
        try await repository.add(todo)
        logger.log("Todoを追加: \(title)")
        return todo
    }

    public func toggleCompletion(_ todo: Todo) async throws -> Todo {
        var updated = todo
        updated.isCompleted.toggle()
        try await repository.update(updated)
        logger.log("Todoの完了状態を変更: \(todo.title) → \(updated.isCompleted)")
        return updated
    }

    public func delete(id: UUID) async throws {
        try await repository.delete(id: id)
        logger.log("Todoを削除: \(id)")
    }
}
