import Foundation
import Testing
import SwiftInjectable
@testable import BasicExample

@Suite("FeatureViewModel テスト")
struct FeatureViewModelTests {

    @Test("UseCase 経由でユーザー取得が成功する")
    @MainActor
    func fetchUserSuccess() async {
        let mockUseCase = FetchUserUseCaseProtocolMock()
        mockUseCase.executeHandler = { userId in
            User(id: userId, name: "Test User \(userId)")
        }

        let mockLogger = LoggerProtocolMock()

        let vm = FeatureViewModel(
            fetchUserUseCase: mockUseCase,
            logger: mockLogger
        )
        await vm.fetch(userId: 42)

        #expect(vm.userName == "Test User 42")
        #expect(vm.isLoading == false)
        #expect(mockUseCase.executeCallCount == 1)
        #expect(mockLogger.logCallCount == 1)
    }

    @Test("UseCase が失敗してもクラッシュしない")
    @MainActor
    func fetchUserFailure() async {
        let mockUseCase = FetchUserUseCaseProtocolMock()
        mockUseCase.executeHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        let mockLogger = LoggerProtocolMock()

        let vm = FeatureViewModel(
            fetchUserUseCase: mockUseCase,
            logger: mockLogger
        )
        await vm.fetch(userId: 1)

        #expect(vm.userName == "")
        #expect(vm.isLoading == false)
        #expect(mockLogger.logCallCount == 1)
    }
}

@Suite("UserDetailViewModel テスト")
struct UserDetailViewModelTests {

    @Test("追加引数付きの直接注入")
    @MainActor
    func fetchWithDirectInjection() async {
        let mockAPIClient = APIClientProtocolMock()
        mockAPIClient.fetchUserHandler = { id in
            User(id: id, name: "Detail User \(id)")
        }

        let mockLogger = LoggerProtocolMock()

        let vm = UserDetailViewModel(
            apiClient: mockAPIClient,
            logger: mockLogger,
            userId: 99
        )

        #expect(vm.userId == 99)

        await vm.fetch()

        #expect(vm.userName == "Detail User 99")
        #expect(vm.isLoading == false)
        #expect(mockAPIClient.fetchUserCallCount == 1)
        #expect(mockLogger.logCallCount == 1)
    }

    @Test("Container経由の解決も動作する")
    @MainActor
    func fetchViaContainer() async {
        let mockAPIClient = APIClientProtocolMock()
        mockAPIClient.fetchUserHandler = { id in
            User(id: id, name: "Container User \(id)")
        }

        let mockLogger = LoggerProtocolMock()

        let container = Container {
            $0.singleton(APIClientProtocol.self) { _ in mockAPIClient as any APIClientProtocol }
            $0.singleton(LoggerProtocol.self) { _ in mockLogger as any LoggerProtocol }
        }

        let vm = UserDetailViewModel(container: container, userId: 7)
        await vm.fetch()

        #expect(vm.userName == "Container User 7")
        #expect(vm.userId == 7)
    }
}
