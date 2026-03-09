@testable import Domain
import Foundation
import SwiftInjectable
import Testing
import TodoListFeature

@Suite("UseTodoList テスト")
@MainActor
struct UseTodoListTests {

    private func withMocks(
        todos: [Todo] = [],
        configure: ((TodoRepositoryProtocolMock, LoggerProtocolMock) -> Void)? = nil,
        body: (UseTodoList) async throws -> Void
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
            let hook = UseTodoList()
            try await body(hook)
        }
    }

    @Test("fetchAll: 取得成功時にtodosが設定される")
    func fetchAllSuccess() async {
        let expected = [
            Todo(title: "Todo1"),
            Todo(title: "Todo2"),
        ]
        await withMocks(todos: expected, configure: { repo, _ in
            repo.fetchAllHandler = { }
        }) { hook in
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
        await withMocks(configure: { repo, _ in
            repo.fetchAllHandler = {
                throw URLError(.notConnectedToInternet)
            }
        }) { hook in
            await hook.fetchAll()

            #expect(hook.error != nil)
            #expect(hook.isLoading == false)
        }
    }

    @Test("toggleCompletion: Repositoryが呼ばれる")
    func toggleCompletion() async {
        let todo = Todo(title: "タスク", isCompleted: false)
        await withMocks(todos: [todo], configure: { repo, _ in
            repo.updateHandler = { _ in }
        }) { hook in
            await hook.toggleCompletion(todo)

            #expect(hook.error == nil)
        }
    }

    @Test("toggleCompletion: 失敗時にerrorが設定される")
    func toggleCompletionFailure() async {
        let todo = Todo(title: "タスク", isCompleted: false)
        await withMocks(todos: [todo], configure: { repo, _ in
            repo.updateHandler = { _ in
                throw URLError(.badServerResponse)
            }
        }) { hook in
            await hook.toggleCompletion(todo)

            #expect(hook.error != nil)
        }
    }

    @Test("delete: Repositoryが呼ばれる")
    func deleteSuccess() async {
        let todo = Todo(title: "削除対象")
        await withMocks(todos: [todo], configure: { repo, _ in
            repo.deleteHandler = { _ in }
        }) { hook in
            await hook.delete(id: todo.id)

            #expect(hook.error == nil)
        }
    }

    @Test("delete: 失敗時にerrorが設定される")
    func deleteFailure() async {
        let todo = Todo(title: "削除対象")
        await withMocks(todos: [todo], configure: { repo, _ in
            repo.deleteHandler = { _ in throw URLError(.badServerResponse) }
        }) { hook in
            await hook.delete(id: todo.id)

            #expect(hook.error != nil)
        }
    }

    @Test("add: Repositoryが呼ばれる")
    func addSuccess() async {
        await withMocks(configure: { repo, _ in
            repo.addHandler = { _ in }
        }) { hook in
            await hook.add(title: "新規Todo")

            #expect(hook.error == nil)
        }
    }

    @Test("clearError: エラーがクリアされる")
    func clearError() async {
        await withMocks(configure: { repo, _ in
            repo.fetchAllHandler = { throw URLError(.badURL) }
        }) { hook in
            await hook.fetchAll()

            #expect(hook.error != nil)
            hook.clearError()
            #expect(hook.error == nil)
        }
    }
}
