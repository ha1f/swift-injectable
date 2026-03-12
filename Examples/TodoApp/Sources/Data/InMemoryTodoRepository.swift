import Domain
import Foundation

/// インメモリのTodoリポジトリ実装
public actor InMemoryTodoRepository: TodoRepositoryProtocol {
    private var todos: [Todo]

    public init(initialTodos: [Todo] = []) {
        self.todos = initialTodos
    }

    public func fetchAll() async throws -> [Todo] {
        todos
    }

    public func add(_ todo: Todo) async throws {
        todos.append(todo)
    }

    public func update(_ todo: Todo) async throws {
        guard let index = todos.firstIndex(where: { $0.id == todo.id }) else {
            throw TodoRepositoryError.notFound
        }
        todos[index] = todo
    }

    public func delete(id: UUID) async throws {
        guard let index = todos.firstIndex(where: { $0.id == id }) else {
            throw TodoRepositoryError.notFound
        }
        todos.remove(at: index)
    }
}

/// リポジトリのエラー
public enum TodoRepositoryError: Error, Equatable {
    case notFound
}
