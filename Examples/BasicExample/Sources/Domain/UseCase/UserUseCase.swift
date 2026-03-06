import Foundation

struct UserUseCase: UserUseCaseProtocol {
    let apiClient: any APIClientProtocol

    func execute(userId: Int) async throws -> User {
        try await apiClient.fetchUser(id: userId)
    }
}
