@testable import Domain
import Foundation
import Presentation
import SwiftInjectable
import Testing

@Suite("UseFetchUser テスト")
@MainActor
struct UseFetchUserTests {

    @Test("取得成功時: user が設定され、isLoading が false になる")
    func fetchSuccess() async {
        let mockUseCase = UserUseCaseProtocolMock()
        mockUseCase.fetchHandler = { userId in
            User(id: userId, name: "Test User \(userId)")
        }
        let mockLogger = LoggerProtocolMock()
        mockLogger.logHandler = { _ in }

        await withTestInjection(configure: { store in
            store.register(mockUseCase, for: (any UserUseCaseProtocol).self)
            store.register(mockLogger, for: (any LoggerProtocol).self)
        }) {
            let fetchUser = UseFetchUser()

            // 初期状態
            #expect(fetchUser.user == nil)
            #expect(fetchUser.isLoading == false)
            #expect(fetchUser.error == nil)

            await fetchUser.fetch(userId: 42)

            // 状態が更新されている
            #expect(fetchUser.user?.id == 42)
            #expect(fetchUser.user?.name == "Test User 42")
            #expect(fetchUser.isLoading == false)
            #expect(fetchUser.error == nil)

            // mock が呼ばれている
            #expect(mockUseCase.fetchCallCount == 1)
            #expect(mockLogger.logCallCount == 1)
        }
    }

    @Test("取得失敗時: error が設定され、user は nil のまま")
    func fetchFailure() async {
        let mockUseCase = UserUseCaseProtocolMock()
        mockUseCase.fetchHandler = { (_: Int) in
            throw URLError(.notConnectedToInternet)
        }
        let mockLogger = LoggerProtocolMock()
        mockLogger.logHandler = { _ in }

        await withTestInjection(configure: { store in
            store.register(mockUseCase, for: (any UserUseCaseProtocol).self)
            store.register(mockLogger, for: (any LoggerProtocol).self)
        }) {
            let fetchUser = UseFetchUser()
            await fetchUser.fetch(userId: 1)

            // user は nil のまま、error が設定されている
            #expect(fetchUser.user == nil)
            #expect(fetchUser.isLoading == false)
            #expect(fetchUser.error != nil)

            // mock が呼ばれている
            #expect(mockUseCase.fetchCallCount == 1)
            #expect(mockLogger.logCallCount == 1)
        }
    }

    @Test("複数回取得: 最後の結果で user が上書きされる")
    func fetchMultipleTimes() async {
        let mockUseCase = UserUseCaseProtocolMock()
        mockUseCase.fetchHandler = { userId in
            User(id: userId, name: "User \(userId)")
        }
        let mockLogger = LoggerProtocolMock()
        mockLogger.logHandler = { _ in }

        await withTestInjection(configure: { store in
            store.register(mockUseCase, for: (any UserUseCaseProtocol).self)
            store.register(mockLogger, for: (any LoggerProtocol).self)
        }) {
            let fetchUser = UseFetchUser()

            await fetchUser.fetch(userId: 1)
            #expect(fetchUser.user?.name == "User 1")

            await fetchUser.fetch(userId: 99)
            #expect(fetchUser.user?.name == "User 99")

            #expect(mockUseCase.fetchCallCount == 2)
        }
    }
}
