@testable import Domain
import Foundation
import SwiftHooksQuery
import SwiftInjectable
import Testing
import TodoStatsFeature

@Suite("UseTodoStats テスト")
@MainActor
struct UseTodoStatsTests {

    private func withMocks(
        todos: [Todo] = [],
        body: (UseTodoStats) async throws -> Void
    ) async rethrows {
        let mockRepo = TodoRepositoryProtocolMock()
        mockRepo.fetchAllHandler = { todos }
        let mockLogger = LoggerProtocolMock()
        mockLogger.logHandler = { _ in }

        try await withTestInjection(configure: { store in
            store.register(mockRepo, for: (any TodoRepositoryProtocol).self)
            store.register(mockLogger, for: (any LoggerProtocol).self)
            _ = store.queryCache
        }) {
            let hook = UseTodoStats()
            // QueryCache にデータをロード
            await hook.todoList.fetchAll()
            try await body(hook)
        }
    }

    @Test("初期状態: すべてゼロの統計")
    func initialStats() async {
        let mockRepo = TodoRepositoryProtocolMock()
        mockRepo.fetchAllHandler = { [] }
        let mockLogger = LoggerProtocolMock()
        mockLogger.logHandler = { _ in }

        await withTestInjection(configure: { store in
            store.register(mockRepo, for: (any TodoRepositoryProtocol).self)
            store.register(mockLogger, for: (any LoggerProtocol).self)
            _ = store.queryCache
        }) {
            let hook = UseTodoStats()
            // fetchAll を呼ばない状態
            #expect(hook.stats == TodoStats(total: 0, active: 0, completed: 0))
            #expect(hook.completionRate == 0)
        }
    }

    @Test("todosから統計を計算する")
    func computeStats() async {
        let todos = [
            Todo(title: "Todo1", isCompleted: false),
            Todo(title: "Todo2", isCompleted: true),
            Todo(title: "Todo3", isCompleted: false),
            Todo(title: "Todo4", isCompleted: true),
            Todo(title: "Todo5", isCompleted: true),
        ]
        await withMocks(todos: todos) { hook in
            #expect(hook.stats.total == 5)
            #expect(hook.stats.active == 2)
            #expect(hook.stats.completed == 3)
            #expect(hook.completionRate == 0.6)
        }
    }

    @Test("すべて完了: 完了率100%")
    func allCompleted() async {
        let todos = [
            Todo(title: "Todo1", isCompleted: true),
            Todo(title: "Todo2", isCompleted: true),
        ]
        await withMocks(todos: todos) { hook in
            #expect(hook.stats == TodoStats(total: 2, active: 0, completed: 2))
            #expect(hook.completionRate == 1.0)
        }
    }

    @Test("すべて未完了: 完了率0%")
    func allActive() async {
        let todos = [
            Todo(title: "Todo1", isCompleted: false),
            Todo(title: "Todo2", isCompleted: false),
        ]
        await withMocks(todos: todos) { hook in
            #expect(hook.stats == TodoStats(total: 2, active: 2, completed: 0))
            #expect(hook.completionRate == 0.0)
        }
    }
}
