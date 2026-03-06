import Foundation

final class FetchUserUseCase: FetchUserUseCaseProtocol {
    private let apiClient: any APIClientProtocol

    init(apiClient: any APIClientProtocol) {
        self.apiClient = apiClient
    }

    func execute(userId: Int) async throws -> User {
        try await apiClient.fetchUser(id: userId)
    }
}
