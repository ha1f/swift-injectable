import Domain
import SwiftHooks
import SwiftInjectable
import SwiftUI

/// Todoリストの状態管理を提供するhook
/// todosはUseCase（Repository）から直接参照するため、
/// 他のhookからのadd/deleteも自動的に反映される
@Hook
@MainActor
public struct UseTodoList {
    @Injected var todoUseCase: any TodoUseCaseProtocol

    public var isLoading: Bool = false
    public var error: (any Error)? = nil

    /// Repository が保持する最新のTodoリスト
    public var todos: [Todo] {
        todoUseCase.todos
    }

    /// Todo一覧を取得する
    public func fetchAll() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await todoUseCase.fetchAll()
            error = nil
        } catch {
            self.error = error
        }
    }

    /// Todoの完了状態をトグルする
    public func toggleCompletion(_ todo: Todo) async {
        do {
            try await todoUseCase.toggleCompletion(todo)
            error = nil
        } catch {
            self.error = error
        }
    }

    /// Todoを削除する
    public func delete(id: UUID) async {
        do {
            try await todoUseCase.delete(id: id)
            error = nil
        } catch {
            self.error = error
        }
    }

    /// Todoを追加する
    public func add(title: String) async {
        do {
            try await todoUseCase.add(title: title)
            error = nil
        } catch {
            self.error = error
        }
    }

    /// エラーをクリアする
    public func clearError() {
        error = nil
    }
}
