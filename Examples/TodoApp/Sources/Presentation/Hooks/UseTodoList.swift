import Domain
import SwiftHooks
import SwiftInjectable
import SwiftUI

/// Todoリストの状態管理を提供するhook
@Hook
@MainActor
public struct UseTodoList {
    @Injected var todoUseCase: any TodoUseCaseProtocol

    public var todos: [Todo] = []
    public var isLoading: Bool = false
    public var error: (any Error)? = nil

    /// Todo一覧を取得する
    public func fetchAll() async {
        isLoading = true
        defer { isLoading = false }
        do {
            todos = try await todoUseCase.fetchAll()
            error = nil
        } catch {
            self.error = error
        }
    }

    /// Todoの完了状態をトグルする（楽観的更新）
    public func toggleCompletion(_ todo: Todo) async {
        // 楽観的更新: 先にローカル状態を変更
        if let index = todos.firstIndex(where: { $0.id == todo.id }) {
            todos[index].isCompleted.toggle()
        }
        do {
            _ = try await todoUseCase.toggleCompletion(todo)
        } catch {
            // 失敗時はロールバック
            if let index = todos.firstIndex(where: { $0.id == todo.id }) {
                todos[index].isCompleted.toggle()
            }
            self.error = error
        }
    }

    /// Todoを削除する
    public func delete(id: UUID) async {
        do {
            try await todoUseCase.delete(id: id)
            todos.removeAll { $0.id == id }
            error = nil
        } catch {
            self.error = error
        }
    }

    /// Todoを追加し、リストに反映する
    public func add(title: String) async {
        do {
            let todo = try await todoUseCase.add(title: title)
            todos.append(todo)
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
