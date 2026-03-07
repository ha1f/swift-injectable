@testable import Domain
import Foundation
import Presentation
import SwiftInjectable
import Testing

@Suite("UseFetchUser テスト", .serialized)
@MainActor
struct UseFetchUserTests {

    @Test("ユーザー取得が成功し、UseCase と Logger が呼ばれる")
    func fetchSuccess() async {
        let mockUseCase = UserUseCaseProtocolMock()
        mockUseCase.fetchHandler = { userId in
            User(id: userId, name: "Test User \(userId)")
        }
        let mockLogger = LoggerProtocolMock()
        mockLogger.logHandler = { _ in }

        await withTestInjection(configure: { store in
            store.register(mockUseCase as any UserUseCaseProtocol, as: (any UserUseCaseProtocol).self)
            store.register(mockLogger as any LoggerProtocol, as: (any LoggerProtocol).self)
        }) {
            var fetchUser = UseFetchUser()
            await fetchUser.fetch(userId: 42)

            #expect(mockUseCase.fetchCallCount == 1)
            #expect(mockLogger.logCallCount == 1)
        }
    }

    @Test("ユーザー取得が失敗した場合、エラーがログされる")
    func fetchFailure() async {
        let mockUseCase = UserUseCaseProtocolMock()
        mockUseCase.fetchHandler = { (_: Int) in
            throw URLError(.notConnectedToInternet)
        }
        let mockLogger = LoggerProtocolMock()
        mockLogger.logHandler = { _ in }

        await withTestInjection(configure: { store in
            store.register(mockUseCase as any UserUseCaseProtocol, as: (any UserUseCaseProtocol).self)
            store.register(mockLogger as any LoggerProtocol, as: (any LoggerProtocol).self)
        }) {
            var fetchUser = UseFetchUser()
            await fetchUser.fetch(userId: 1)

            #expect(mockUseCase.fetchCallCount == 1)
            // エラー時もログが呼ばれる
            #expect(mockLogger.logCallCount == 1)
        }
    }
}
