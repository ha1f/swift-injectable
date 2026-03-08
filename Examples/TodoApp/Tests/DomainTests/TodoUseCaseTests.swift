import Foundation
import Testing
@testable import Domain

@Suite("TodoUseCase テスト")
struct TodoUseCaseTests {

    @Test("fetchAll: リポジトリからTodo一覧を取得する")
    func fetchAll() async throws {
        let mockRepo = TodoRepositoryProtocolMock()
        let expected = [
            Todo(title: "テスト1"),
            Todo(title: "テスト2"),
        ]
        mockRepo.fetchAllHandler = { expected }

        let mockLogger = LoggerProtocolMock()
        mockLogger.logHandler = { _ in }

        let useCase = TodoUseCase(repository: mockRepo, logger: mockLogger)
        let result = try await useCase.fetchAll()

        #expect(result == expected)
        #expect(mockRepo.fetchAllCallCount == 1)
        #expect(mockLogger.logCallCount == 1)
    }

    @Test("add: 新しいTodoを追加する")
    func add() async throws {
        let mockRepo = TodoRepositoryProtocolMock()
        mockRepo.addHandler = { _ in }

        let mockLogger = LoggerProtocolMock()
        mockLogger.logHandler = { _ in }

        let useCase = TodoUseCase(repository: mockRepo, logger: mockLogger)
        let todo = try await useCase.add(title: "新しいTodo")

        #expect(todo.title == "新しいTodo")
        #expect(todo.isCompleted == false)
        #expect(mockRepo.addCallCount == 1)
    }

    @Test("toggleCompletion: 完了状態を反転する")
    func toggleCompletion() async throws {
        let mockRepo = TodoRepositoryProtocolMock()
        mockRepo.updateHandler = { _ in }

        let mockLogger = LoggerProtocolMock()
        mockLogger.logHandler = { _ in }

        let useCase = TodoUseCase(repository: mockRepo, logger: mockLogger)
        let original = Todo(title: "タスク", isCompleted: false)
        let toggled = try await useCase.toggleCompletion(original)

        #expect(toggled.isCompleted == true)
        #expect(toggled.title == "タスク")
        #expect(mockRepo.updateCallCount == 1)
    }

    @Test("delete: Todoを削除する")
    func delete() async throws {
        let mockRepo = TodoRepositoryProtocolMock()
        mockRepo.deleteHandler = { _ in }

        let mockLogger = LoggerProtocolMock()
        mockLogger.logHandler = { _ in }

        let useCase = TodoUseCase(repository: mockRepo, logger: mockLogger)
        let id = UUID()
        try await useCase.delete(id: id)

        #expect(mockRepo.deleteCallCount == 1)
    }

    @Test("fetchAll: リポジトリがエラーを返した場合")
    func fetchAllError() async {
        let mockRepo = TodoRepositoryProtocolMock()
        mockRepo.fetchAllHandler = {
            throw URLError(.notConnectedToInternet)
        }

        let mockLogger = LoggerProtocolMock()
        mockLogger.logHandler = { _ in }

        let useCase = TodoUseCase(repository: mockRepo, logger: mockLogger)

        do {
            _ = try await useCase.fetchAll()
            Issue.record("エラーが発生するはず")
        } catch {
            #expect(error is URLError)
        }
    }
}
