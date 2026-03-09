@testable import Domain
import Foundation
import SwiftInjectable
import Testing
import TodoListFeature

@Suite("UseTodoListView テスト")
@MainActor
struct UseTodoListViewTests {

    // MARK: - filteredTodos

    @Test("filteredTodos: allフィルターですべてのTodoを返す")
    func filteredTodosAll() async {
        let todos = [
            Todo(title: "Todo1", isCompleted: false),
            Todo(title: "Todo2", isCompleted: true),
        ]
        let mockUseCase = TodoUseCaseProtocolMock()
        mockUseCase._todos = todos

        await withTestInjection(configure: { store in
            store.register(mockUseCase, for: (any TodoUseCaseProtocol).self)
        }) {
            let hook = UseTodoListView()

            #expect(hook.filteredTodos.count == 2)
        }
    }

    @Test("filteredTodos: activeフィルターで未完了のみ返す")
    func filteredTodosActive() async {
        let todos = [
            Todo(title: "Todo1", isCompleted: false),
            Todo(title: "Todo2", isCompleted: true),
            Todo(title: "Todo3", isCompleted: false),
        ]
        let mockUseCase = TodoUseCaseProtocolMock()
        mockUseCase._todos = todos

        await withTestInjection(configure: { store in
            store.register(mockUseCase, for: (any TodoUseCaseProtocol).self)
        }) {
            let hook = UseTodoListView()
            hook.filter.currentFilter = .active

            #expect(hook.filteredTodos.count == 2)
            #expect(hook.filteredTodos.allSatisfy { !$0.isCompleted })
        }
    }

    // MARK: - deleteAtOffsets

    @Test("deleteAtOffsets: フィルタ済みリストからIndexSetで削除する")
    func deleteAtOffsets() async {
        let todos = [
            Todo(title: "未完了1", isCompleted: false),
            Todo(title: "完了1", isCompleted: true),
            Todo(title: "未完了2", isCompleted: false),
        ]
        let mockUseCase = TodoUseCaseProtocolMock()
        mockUseCase._todos = todos
        mockUseCase.deleteHandler = { _ in }

        await withTestInjection(configure: { store in
            store.register(mockUseCase, for: (any TodoUseCaseProtocol).self)
        }) {
            let hook = UseTodoListView()
            hook.filter.currentFilter = .active

            #expect(hook.filteredTodos.count == 2)

            hook.deleteAtOffsets(IndexSet(integer: 0))

            try? await Task.sleep(for: .milliseconds(10))
            #expect(mockUseCase.deleteCallCount == 1)
        }
    }

    // MARK: - hasError / errorMessage

    @Test("hasError: エラーがない場合はfalse")
    func hasErrorFalse() async {
        let mockUseCase = TodoUseCaseProtocolMock()
        mockUseCase._todos = []
        mockUseCase.fetchAllHandler = { }

        await withTestInjection(configure: { store in
            store.register(mockUseCase, for: (any TodoUseCaseProtocol).self)
        }) {
            let hook = UseTodoListView()
            await hook.todoList.fetchAll()

            #expect(hook.hasError == false)
            #expect(hook.errorMessage == "")
        }
    }

    @Test("hasError: エラーがある場合はtrue")
    func hasErrorTrue() async {
        let mockUseCase = TodoUseCaseProtocolMock()
        mockUseCase._todos = []
        mockUseCase.fetchAllHandler = {
            throw URLError(.notConnectedToInternet)
        }

        await withTestInjection(configure: { store in
            store.register(mockUseCase, for: (any TodoUseCaseProtocol).self)
        }) {
            let hook = UseTodoListView()
            await hook.todoList.fetchAll()

            #expect(hook.hasError == true)
            #expect(!hook.errorMessage.isEmpty)
        }
    }

    // MARK: - dismissError

    @Test("dismissError: エラーがクリアされる")
    func dismissError() async {
        let mockUseCase = TodoUseCaseProtocolMock()
        mockUseCase._todos = []
        mockUseCase.fetchAllHandler = {
            throw URLError(.badURL)
        }

        await withTestInjection(configure: { store in
            store.register(mockUseCase, for: (any TodoUseCaseProtocol).self)
        }) {
            let hook = UseTodoListView()
            await hook.todoList.fetchAll()

            #expect(hook.hasError == true)
            hook.dismissError()
            #expect(hook.hasError == false)
        }
    }

    // MARK: - retry

    @Test("retry: fetchAllが呼ばれる")
    func retry() async {
        let mockUseCase = TodoUseCaseProtocolMock()
        mockUseCase._todos = [Todo(title: "Todo1")]
        mockUseCase.fetchAllHandler = { }

        await withTestInjection(configure: { store in
            store.register(mockUseCase, for: (any TodoUseCaseProtocol).self)
        }) {
            let hook = UseTodoListView()
            await hook.retry()
            #expect(hook.todoList.todos.count == 1)

            await hook.retry()
            #expect(mockUseCase.fetchAllCallCount == 2)
        }
    }

    // MARK: - showForm / submitForm

    @Test("showForm: isFormPresentedがtrueになる")
    func showForm() async {
        let mockUseCase = TodoUseCaseProtocolMock()
        mockUseCase._todos = []

        await withTestInjection(configure: { store in
            store.register(mockUseCase, for: (any TodoUseCaseProtocol).self)
        }) {
            let hook = UseTodoListView()

            #expect(hook.isFormPresented == false)
            hook.showForm()
            #expect(hook.isFormPresented == true)
        }
    }

    @Test("submitForm: isFormPresentedがfalseになりaddが呼ばれる")
    func submitForm() async {
        let mockUseCase = TodoUseCaseProtocolMock()
        mockUseCase._todos = []
        mockUseCase.addHandler = { _ in }

        await withTestInjection(configure: { store in
            store.register(mockUseCase, for: (any TodoUseCaseProtocol).self)
        }) {
            let hook = UseTodoListView()
            hook.showForm()

            #expect(hook.isFormPresented == true)
            hook.submitForm(title: "新規Todo")
            #expect(hook.isFormPresented == false)

            try? await Task.sleep(for: .milliseconds(10))
            #expect(mockUseCase.addCallCount == 1)
        }
    }
}
