@testable import Domain
import Foundation
import Presentation
import SwiftInjectable
import Testing

@Suite("UseTodoList テスト")
@MainActor
struct UseTodoListTests {

    @Test("fetchAll: 取得成功時にtodosが設定される")
    func fetchAllSuccess() async {
        let mockUseCase = TodoUseCaseProtocolMock()
        let expected = [
            Todo(title: "Todo1"),
            Todo(title: "Todo2"),
        ]
        mockUseCase.fetchAllHandler = { expected }

        await withTestInjection(configure: { store in
            store.register(mockUseCase, for: (any TodoUseCaseProtocol).self)
        }) {
            let hook = UseTodoList()

            // 初期状態
            #expect(hook.todos.isEmpty)
            #expect(hook.isLoading == false)
            #expect(hook.error == nil)

            await hook.fetchAll()

            #expect(hook.todos == expected)
            #expect(hook.isLoading == false)
            #expect(hook.error == nil)
            #expect(mockUseCase.fetchAllCallCount == 1)
        }
    }

    @Test("fetchAll: 取得失敗時にerrorが設定される")
    func fetchAllFailure() async {
        let mockUseCase = TodoUseCaseProtocolMock()
        mockUseCase.fetchAllHandler = {
            throw URLError(.notConnectedToInternet)
        }

        await withTestInjection(configure: { store in
            store.register(mockUseCase, for: (any TodoUseCaseProtocol).self)
        }) {
            let hook = UseTodoList()
            await hook.fetchAll()

            #expect(hook.todos.isEmpty)
            #expect(hook.error != nil)
            #expect(hook.isLoading == false)
        }
    }

    @Test("toggleCompletion: 楽観的更新でローカル状態が即座に変わる")
    func toggleCompletionOptimistic() async {
        let todo = Todo(title: "タスク", isCompleted: false)
        let mockUseCase = TodoUseCaseProtocolMock()
        mockUseCase.fetchAllHandler = { [todo] }
        mockUseCase.toggleCompletionHandler = { t in
            var updated = t
            updated.isCompleted.toggle()
            return updated
        }

        await withTestInjection(configure: { store in
            store.register(mockUseCase, for: (any TodoUseCaseProtocol).self)
        }) {
            let hook = UseTodoList()
            await hook.fetchAll()

            #expect(hook.todos[0].isCompleted == false)

            await hook.toggleCompletion(todo)

            #expect(hook.todos[0].isCompleted == true)
            #expect(mockUseCase.toggleCompletionCallCount == 1)
        }
    }

    @Test("toggleCompletion: 失敗時にロールバックされる")
    func toggleCompletionRollback() async {
        let todo = Todo(title: "タスク", isCompleted: false)
        let mockUseCase = TodoUseCaseProtocolMock()
        mockUseCase.fetchAllHandler = { [todo] }
        mockUseCase.toggleCompletionHandler = { _ in
            throw URLError(.badServerResponse)
        }

        await withTestInjection(configure: { store in
            store.register(mockUseCase, for: (any TodoUseCaseProtocol).self)
        }) {
            let hook = UseTodoList()
            await hook.fetchAll()
            await hook.toggleCompletion(todo)

            // ロールバックで元に戻る
            #expect(hook.todos[0].isCompleted == false)
            #expect(hook.error != nil)
        }
    }

    @Test("delete: Todoが削除される")
    func deleteSuccess() async {
        let todo = Todo(title: "削除対象")
        let mockUseCase = TodoUseCaseProtocolMock()
        mockUseCase.fetchAllHandler = { [todo] }
        mockUseCase.deleteHandler = { _ in }

        await withTestInjection(configure: { store in
            store.register(mockUseCase, for: (any TodoUseCaseProtocol).self)
        }) {
            let hook = UseTodoList()
            await hook.fetchAll()

            #expect(hook.todos.count == 1)

            await hook.delete(id: todo.id)

            #expect(hook.todos.isEmpty)
            #expect(mockUseCase.deleteCallCount == 1)
        }
    }

    @Test("delete: 失敗時にerrorが設定される")
    func deleteFailure() async {
        let todo = Todo(title: "削除対象")
        let mockUseCase = TodoUseCaseProtocolMock()
        mockUseCase.fetchAllHandler = { [todo] }
        mockUseCase.deleteHandler = { _ in throw URLError(.badServerResponse) }

        await withTestInjection(configure: { store in
            store.register(mockUseCase, for: (any TodoUseCaseProtocol).self)
        }) {
            let hook = UseTodoList()
            await hook.fetchAll()
            await hook.delete(id: todo.id)

            // 削除失敗なのでtodosはそのまま
            #expect(hook.todos.count == 1)
            #expect(hook.error != nil)
        }
    }

    @Test("add: 新しいTodoが追加される")
    func addSuccess() async {
        let mockUseCase = TodoUseCaseProtocolMock()
        mockUseCase.fetchAllHandler = { [] }
        let newTodo = Todo(title: "新規Todo")
        mockUseCase.addHandler = { _ in newTodo }

        await withTestInjection(configure: { store in
            store.register(mockUseCase, for: (any TodoUseCaseProtocol).self)
        }) {
            let hook = UseTodoList()
            await hook.fetchAll()

            #expect(hook.todos.isEmpty)

            await hook.add(title: "新規Todo")

            #expect(hook.todos.count == 1)
            #expect(hook.todos[0].title == "新規Todo")
        }
    }

    @Test("clearError: エラーがクリアされる")
    func clearError() async {
        let mockUseCase = TodoUseCaseProtocolMock()
        mockUseCase.fetchAllHandler = { throw URLError(.badURL) }

        await withTestInjection(configure: { store in
            store.register(mockUseCase, for: (any TodoUseCaseProtocol).self)
        }) {
            let hook = UseTodoList()
            await hook.fetchAll()

            #expect(hook.error != nil)

            hook.clearError()

            #expect(hook.error == nil)
        }
    }
}
