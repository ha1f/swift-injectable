@testable import Domain
import Presentation
import SwiftInjectable
import SwiftUI
import Testing

@Suite("UseFetchUser テスト")
@MainActor
struct UseFetchUserTests {

    @Test("モック UseCase でユーザー取得が成功する")
    func fetchSuccess() async throws {
        let mockUseCase = UserUseCaseProtocolMock()
        mockUseCase.fetchHandler = { userId in
            User(id: userId, name: "Test User \(userId)")
        }

        var store = InjectionStore()
        store.register(mockUseCase as any UserUseCaseProtocol, as: (any UserUseCaseProtocol).self)

        let resolved = store.resolve((any UserUseCaseProtocol).self)!
        let user = try await resolved.fetch(userId: 42)

        #expect(user.id == 42)
        #expect(user.name == "Test User 42")
        #expect(mockUseCase.fetchCallCount == 1)
    }

    @Test("UseCase がエラーを返した場合")
    func fetchFailure() async {
        let mockUseCase = UserUseCaseProtocolMock()
        mockUseCase.fetchHandler = { (_: Int) in
            throw URLError(.notConnectedToInternet)
        }

        do {
            _ = try await mockUseCase.fetch(userId: 1)
            Issue.record("エラーが発生するはず")
        } catch {
            #expect(error is URLError)
        }
    }

    @Test("InjectionStore に複数の依存を登録して解決できる")
    func storeRegistration() {
        let mockLogger = LoggerProtocolMock()
        mockLogger.logHandler = { _ in }
        let mockUseCase = UserUseCaseProtocolMock()

        var store = InjectionStore()
        store.register(mockLogger as any LoggerProtocol, as: (any LoggerProtocol).self)
        store.register(mockUseCase as any UserUseCaseProtocol, as: (any UserUseCaseProtocol).self)

        #expect(store.resolve((any LoggerProtocol).self) != nil)
        #expect(store.resolve((any UserUseCaseProtocol).self) != nil)
    }

    @Test("モックロガーが正しく呼ばれる")
    func loggerIsCalled() {
        let mockLogger = LoggerProtocolMock()
        mockLogger.logHandler = { _ in }

        let logger: any LoggerProtocol = mockLogger
        logger.log("test message")

        #expect(mockLogger.logCallCount == 1)
    }
}
