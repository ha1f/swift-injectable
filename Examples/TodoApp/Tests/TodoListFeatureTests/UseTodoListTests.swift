@testable import Domain
import Foundation
import SwiftInjectable
import Testing
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
        let mockUseCase = TodoUseCaseProtocolMock()
        mockUseCase._todos = expected
        mockUseCase.fetchAllHandler = { }

        await withTestInjection(configure: { store in
            store.register(mockUseCase, for: (any TodoUseCaseProtocol).self)
        }) {
            let hook = UseTodoList()

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
        mockUseCase._todos = []
        mockUseCase.fetchAllHandler = {
            throw URLError(.notConnectedToInternet)
        }

        await withTestInjection(configure: { store in
            store.register(mockUseCase, for: (any TodoUseCaseProtocol).self)
        }) {
            let hook = UseTodoList()
            await hook.fetchAll()

            #expect(hook.error != nil)
            #expect(hook.isLoading == false)
        }
    }

    @Test("toggleCompletion: UseCaseが呼ばれる")
    func toggleCompletion() async {
        let todo = Todo(title: "タスク", isCompleted: false)
        let mockUseCase = TodoUseCaseProtocolMock()
        mockUseCase._todos = [todo]
        mockUseCase.fetchAllHandler = { }
        mockUseCase.toggleCompletionHandler = { _ in }

        await withTestInjection(configure: { store in
            store.register(mockUseCase, for: (any TodoUseCaseProtocol).self)
        }) {
            let hook = UseTodoList()
            await hook.toggleCompletion(todo)

            #expect(mockUseCase.toggleCompletionCallCount == 1)
            #expect(hook.error == nil)
        }
    }

    @Test("toggleCompletion: 失敗時にerrorが設定される")
    func toggleCompletionFailure() async {
        let todo = Todo(title: "タスク", isCompleted: false)
        let mockUseCase = TodoUseCaseProtocolMock()
        mockUseCase._todos = [todo]
        mockUseCase.toggleCompletionHandler = { _ in
            throw URLError(.badServerResponse)
        }

        await withTestInjection(configure: { store in
            store.register(mockUseCase, for: (any TodoUseCaseProtocol).self)
        }) {
            let hook = UseTodoList()
            await hook.toggleCompletion(todo)

            #expect(hook.error != nil)
        }
    }

    @Test("delete: UseCaseが呼ばれる")
    func deleteSuccess() async {
        let todo = Todo(title: "削除対象")
        let mockUseCase = TodoUseCaseProtocolMock()
        mockUseCase._todos = [todo]
        mockUseCase.deleteHandler = { _ in }

        await withTestInjection(configure: { store in
            store.register(mockUseCase, for: (any TodoUseCaseProtocol).self)
        }) {
            let hook = UseTodoList()
            await hook.delete(id: todo.id)

            #expect(mockUseCase.deleteCallCount == 1)
            #expect(hook.error == nil)
        }
    }

    @Test("delete: 失敗時にerrorが設定される")
    func deleteFailure() async {
        let todo = Todo(title: "削除対象")
        let mockUseCase = TodoUseCaseProtocolMock()
        mockUseCase._todos = [todo]
        mockUseCase.deleteHandler = { _ in throw URLError(.badServerResponse) }

        await withTestInjection(configure: { store in
            store.register(mockUseCase, for: (any TodoUseCaseProtocol).self)
        }) {
            let hook = UseTodoList()
            await hook.delete(id: todo.id)

            #expect(hook.error != nil)
        }
    }

    @Test("add: UseCaseが呼ばれる")
    func addSuccess() async {
        let mockUseCase = TodoUseCaseProtocolMock()
        mockUseCase._todos = []
        mockUseCase.addHandler = { _ in }

        await withTestInjection(configure: { store in
            store.register(mockUseCase, for: (any TodoUseCaseProtocol).self)
        }) {
            let hook = UseTodoList()
            await hook.add(title: "新規Todo")

            #expect(mockUseCase.addCallCount == 1)
            #expect(hook.error == nil)
        }
    }

    @Test("clearError: エラーがクリアされる")
    func clearError() async {
        let mockUseCase = TodoUseCaseProtocolMock()
        mockUseCase._todos = []
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
