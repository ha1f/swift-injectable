import Domain
import SwiftHooks
import SwiftInjectable
import SwiftUI

/// Todoリストの状態管理を提供するhook
/// UseTodoRepositoryを合成し、ローディング/エラー状態を管理する
@Hook
@MainActor
public struct UseTodoList {
    /// UseTodoRepositoryを合成してRepository操作を委譲する
    public let todoRepo = UseTodoRepository()

    public var isLoading: Bool = false
    public var error: (any Error)? = nil

    /// Repository が保持する最新のTodoリスト
    public var todos: [Todo] {
        todoRepo.todos
    }

    /// Todo一覧を取得する
    public func fetchAll() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await todoRepo.fetchAll()
            error = nil
        } catch {
            self.error = error
        }
    }

    /// Todoの完了状態をトグルする
    public func toggleCompletion(_ todo: Todo) async {
        do {
            try await todoRepo.toggleCompletion(todo)
            error = nil
        } catch {
            self.error = error
        }
    }

    /// Todoを削除する
    public func delete(id: UUID) async {
        do {
            try await todoRepo.delete(id: id)
            error = nil
        } catch {
            self.error = error
        }
    }

    /// Todoを追加する
    public func add(title: String) async {
        do {
            try await todoRepo.add(title: title)
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
