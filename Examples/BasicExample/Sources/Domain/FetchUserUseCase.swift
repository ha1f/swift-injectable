import Foundation
import SwiftInjectableMacros

/// APIClient を使ってユーザーを取得する UseCase
@Injectable
final class FetchUserUseCase: FetchUserUseCaseProtocol, @unchecked Sendable {
    @Inject var apiClient: any APIClientProtocol

    func execute(userId: Int) async throws -> User {
        try await apiClient.fetchUser(id: userId)
    }
}
