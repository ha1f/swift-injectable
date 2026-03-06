import Foundation

final class UserUseCase: UserUseCaseProtocol {
    private let apiClient: any APIClientProtocol

    init(apiClient: any APIClientProtocol) {
        self.apiClient = apiClient
    }

    func execute(userId: Int) async throws -> User {
        try await apiClient.fetchUser(id: userId)
    }
}
