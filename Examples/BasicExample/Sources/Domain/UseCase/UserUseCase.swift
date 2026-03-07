import Foundation

public struct UserUseCase: UserUseCaseProtocol {
    private let apiClient: any APIClientProtocol

    public init(apiClient: any APIClientProtocol) {
        self.apiClient = apiClient
    }

    public func fetch(userId: Int) async throws -> User {
        try await apiClient.fetchUser(id: userId)
    }
}
