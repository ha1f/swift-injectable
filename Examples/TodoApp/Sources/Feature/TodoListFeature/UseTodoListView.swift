import Domain
import SwiftHooks
import SwiftInjectable
import SwiftUI

/// TodoListViewの画面ロジックを管理するhook
/// UseTodoListとUseTodoFilterを合成し、View向けのインターフェースを提供する
@Hook
@MainActor
public struct UseTodoListView {
    public let todoList = UseTodoList()
    public let filter = UseTodoFilter()

    /// フォーム表示状態
    @HookState public var isFormPresented: Bool = false

    /// フィルタ適用済みのTodoリスト
    public var filteredTodos: [Todo] {
        filter.apply(to: todoList.todos)
    }

    /// エラーがあるかどうか
    public var hasError: Bool {
        todoList.error != nil
    }

    /// エラーメッセージ
    public var errorMessage: String {
        todoList.error?.localizedDescription ?? ""
    }

    /// スワイプ削除: IndexSetからフィルタ済みリストのTodoを特定して削除する
    public func deleteAtOffsets(_ indexSet: IndexSet) {
        let filtered = filteredTodos
        for index in indexSet {
            let todo = filtered[index]
            Task {
                await todoList.delete(id: todo.id)
            }
        }
    }

    /// エラーをクリアする
    public func dismissError() {
        todoList.clearError()
    }

    /// リトライ（再取得）
    public func retry() async {
        await todoList.fetchAll()
    }

    /// フォームを表示する
    public func showForm() {
        isFormPresented = true
    }

    /// Todo追加してフォームを閉じる
    public func submitForm(title: String) {
        isFormPresented = false
        Task {
            await todoList.add(title: title)
        }
    }
}
