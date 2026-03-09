import Domain
import Foundation
import Observation

/// インメモリのTodoリポジトリ実装
/// @Observable により、todos の変更が SwiftUI に自動伝播する
@Observable
@MainActor
public final class InMemoryTodoRepository: TodoRepositoryProtocol {
    public private(set) var todos: [Todo]

    public init(initialTodos: [Todo] = []) {
        self.todos = initialTodos
    }

    public func fetchAll() async throws {
        // InMemory なので何もしない（todos は常に最新）
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
