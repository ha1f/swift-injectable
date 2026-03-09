import Foundation
import SwiftHooks
import SwiftInjectable
import SwiftUI

/// Repositoryへのアクセスとビジネスロジックを提供するhook
/// Repository（@Observable）の状態を直接公開するため、
/// このhookを合成する他のhookからも最新の状態が参照できる
@Hook
@MainActor
public struct UseTodoRepository {
    @Injected var repository: any TodoRepositoryProtocol
    @Injected var logger: any LoggerProtocol

    public init() {}

    /// Repository が保持する最新のTodoリスト
    public var todos: [Todo] {
        repository.todos
    }

    /// Todo一覧を取得する
    public func fetchAll() async throws {
        logger.log("Todo一覧を取得")
        try await repository.fetchAll()
    }

    /// Todoを追加する
    public func add(title: String) async throws {
        let todo = Todo(title: title)
        try await repository.add(todo)
        logger.log("Todoを追加: \(title)")
    }

    /// Todoの完了状態をトグルする
    public func toggleCompletion(_ todo: Todo) async throws {
        var updated = todo
        updated.isCompleted.toggle()
        try await repository.update(updated)
        logger.log("Todoの完了状態を変更: \(todo.title) → \(updated.isCompleted)")
    }

    /// Todoを削除する
    public func delete(id: UUID) async throws {
        try await repository.delete(id: id)
        logger.log("Todoを削除: \(id)")
    }
}
