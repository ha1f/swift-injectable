@testable import Domain
import Foundation
import SwiftInjectable
import Testing
import TodoListFeature

@Suite("UseTodoListView テスト")
@MainActor
struct UseTodoListViewTests {

    private func withMocks(
        todos: [Todo] = [],
        configure: ((TodoRepositoryProtocolMock, LoggerProtocolMock) -> Void)? = nil,
        body: (UseTodoListView, TodoRepositoryProtocolMock) async throws -> Void
    ) async rethrows {
        let mockRepo = TodoRepositoryProtocolMock()
        mockRepo._todos = todos
        let mockLogger = LoggerProtocolMock()
        mockLogger.logHandler = { _ in }
        configure?(mockRepo, mockLogger)

        try await withTestInjection(configure: { store in
            store.register(mockRepo, for: (any TodoRepositoryProtocol).self)
            store.register(mockLogger, for: (any LoggerProtocol).self)
        }) {
            let hook = UseTodoListView()
            try await body(hook, mockRepo)
        }
    }

    // MARK: - filteredTodos

    @Test("filteredTodos: allフィルターですべてのTodoを返す")
    func filteredTodosAll() async {
        let todos = [
            Todo(title: "Todo1", isCompleted: false),
            Todo(title: "Todo2", isCompleted: true),
        ]
        await withMocks(todos: todos) { hook, _ in
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
        await withMocks(todos: todos) { hook, _ in
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
        await withMocks(todos: todos, configure: { repo, _ in
            repo.deleteHandler = { _ in }
        }) { hook, repo in
            hook.filter.currentFilter = .active

            #expect(hook.filteredTodos.count == 2)

            hook.deleteAtOffsets(IndexSet(integer: 0))

            try? await Task.sleep(for: .milliseconds(10))
            #expect(repo.deleteCallCount == 1)
        }
    }

    // MARK: - hasError / errorMessage

    @Test("hasError: エラーがない場合はfalse")
    func hasErrorFalse() async {
        await withMocks(configure: { repo, _ in
            repo.fetchAllHandler = { }
        }) { hook, _ in
            await hook.todoList.fetchAll()

            #expect(hook.hasError == false)
            #expect(hook.errorMessage == "")
        }
    }

    @Test("hasError: エラーがある場合はtrue")
    func hasErrorTrue() async {
        await withMocks(configure: { repo, _ in
            repo.fetchAllHandler = {
                throw URLError(.notConnectedToInternet)
            }
        }) { hook, _ in
            await hook.todoList.fetchAll()

            #expect(hook.hasError == true)
            #expect(!hook.errorMessage.isEmpty)
        }
    }

    // MARK: - dismissError

    @Test("dismissError: エラーがクリアされる")
    func dismissError() async {
        await withMocks(configure: { repo, _ in
            repo.fetchAllHandler = {
                throw URLError(.badURL)
            }
        }) { hook, _ in
            await hook.todoList.fetchAll()

            #expect(hook.hasError == true)
            hook.dismissError()
            #expect(hook.hasError == false)
        }
    }

    // MARK: - retry

    @Test("retry: fetchAllが呼ばれる")
    func retry() async {
        let todos = [Todo(title: "Todo1")]
        await withMocks(todos: todos, configure: { repo, _ in
            repo.fetchAllHandler = { }
        }) { hook, repo in
            await hook.retry()
            #expect(hook.todoList.todos.count == 1)

            await hook.retry()
            #expect(repo.fetchAllCallCount == 2)
        }
    }

    // MARK: - showForm / submitForm

    @Test("showForm: isFormPresentedがtrueになる")
    func showForm() async {
        await withMocks { hook, _ in
            #expect(hook.isFormPresented == false)
            hook.showForm()
            #expect(hook.isFormPresented == true)
        }
    }

    @Test("submitForm: isFormPresentedがfalseになりaddが呼ばれる")
    func submitForm() async {
        await withMocks(configure: { repo, _ in
            repo.addHandler = { _ in }
        }) { hook, repo in
            hook.showForm()

            #expect(hook.isFormPresented == true)
            hook.submitForm(title: "新規Todo")
            #expect(hook.isFormPresented == false)

            try? await Task.sleep(for: .milliseconds(10))
            #expect(repo.addCallCount == 1)
        }
    }
}
