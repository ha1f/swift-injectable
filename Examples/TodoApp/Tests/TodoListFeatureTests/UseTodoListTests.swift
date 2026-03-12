@testable import Domain
import Foundation
import SwiftInjectable
import Testing
import TestSupport
import TodoListFeature

@Suite("UseTodoList テスト")
@MainActor
struct UseTodoListTests {

    @Test("fetchAll: 取得成功時にtodosが設定される")
    func fetchAllSuccess() async {
        let expected = [
            Todo(title: "Todo1"),
            Todo(title: "Todo2"),
        ]
        await withTodoMocks(todos: expected) { _ in
            let hook = UseTodoList()

            #expect(hook.isLoading == false)
            #expect(hook.error == nil)

            await hook.fetchAll()

            #expect(hook.todos == expected)
            #expect(hook.isLoading == false)
            #expect(hook.error == nil)
        }
    }

    @Test("fetchAll: 取得失敗時にerrorが設定される")
    func fetchAllFailure() async {
        await withTodoMocks(configure: { repo in
            repo.fetchAllHandler = { throw URLError(.notConnectedToInternet) }
        }) { _ in
            let hook = UseTodoList()
            await hook.fetchAll()

            #expect(hook.error != nil)
            #expect(hook.isLoading == false)
        }
    }

    @Test("toggleCompletion: Repositoryが呼ばれる")
    func toggleCompletion() async {
        let todo = Todo(title: "タスク", isCompleted: false)
        await withTodoMocks(todos: [todo], configure: { repo in
            repo.updateHandler = { _ in }
        }) { _ in
            let hook = UseTodoList()
            await hook.toggleCompletion(todo)

            #expect(hook.error == nil)
        }
    }

    @Test("toggleCompletion: 失敗時にerrorが設定される")
    func toggleCompletionFailure() async {
        let todo = Todo(title: "タスク", isCompleted: false)
        await withTodoMocks(todos: [todo], configure: { repo in
            repo.updateHandler = { _ in throw URLError(.badServerResponse) }
        }) { _ in
            let hook = UseTodoList()
            await hook.toggleCompletion(todo)

            #expect(hook.error != nil)
        }
    }

    @Test("delete: Repositoryが呼ばれる")
    func deleteSuccess() async {
        let todo = Todo(title: "削除対象")
        await withTodoMocks(todos: [todo], configure: { repo in
            repo.deleteHandler = { _ in }
        }) { _ in
            let hook = UseTodoList()
            await hook.delete(id: todo.id)

            #expect(hook.error == nil)
        }
    }

    @Test("delete: 失敗時にerrorが設定される")
    func deleteFailure() async {
        let todo = Todo(title: "削除対象")
        await withTodoMocks(todos: [todo], configure: { repo in
            repo.deleteHandler = { _ in throw URLError(.badServerResponse) }
        }) { _ in
            let hook = UseTodoList()
            await hook.delete(id: todo.id)

            #expect(hook.error != nil)
        }
    }

    @Test("add: Repositoryが呼ばれる")
    func addSuccess() async {
        await withTodoMocks(configure: { repo in
            repo.addHandler = { _ in }
        }) { _ in
            let hook = UseTodoList()
            await hook.add(title: "新規Todo")

            #expect(hook.error == nil)
        }
    }

    @Test("clearError: エラーがクリアされる")
    func clearError() async {
        await withTodoMocks(configure: { repo in
            repo.fetchAllHandler = { throw URLError(.badURL) }
        }) { _ in
            let hook = UseTodoList()
            await hook.fetchAll()

            #expect(hook.error != nil)
            hook.clearError()
            #expect(hook.error == nil)
        }
    }
}
