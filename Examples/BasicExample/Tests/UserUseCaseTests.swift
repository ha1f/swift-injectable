import Foundation
import Testing
@testable import BasicExample

@Suite("UserUseCase テスト")
struct UserUseCaseTests {

    @Test("APIClient 経由でユーザー取得が成功する")
    func fetchUserSuccess() async throws {
        let mockClient = APIClientProtocolMock()
        mockClient.fetchUserHandler = { id in
            User(id: id, name: "Test User \(id)")
        }

        let useCase = UserUseCase(apiClient: mockClient)
        let user = try await useCase.execute(userId: 42)

        #expect(user.id == 42)
        #expect(user.name == "Test User 42")
        #expect(mockClient.fetchUserCallCount == 1)
    }

    @Test("APIClient がエラーを返した場合")
    func fetchUserFailure() async {
        let mockClient = APIClientProtocolMock()
        mockClient.fetchUserHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        let useCase = UserUseCase(apiClient: mockClient)

        do {
            _ = try await useCase.execute(userId: 1)
            Issue.record("エラーが発生するはず")
        } catch {
            #expect(error is URLError)
        }
    }
}
