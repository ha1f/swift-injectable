import Foundation
import SwiftInjectableMacros

@Injectable
@Observable
final class UserDetailViewModel {
    @Dependency let fetchUserUseCase: any FetchUserUseCaseProtocol
    @Dependency let logger: any LoggerProtocol
    let userId: Int

    var userName: String = ""
    var isLoading: Bool = false

    @MainActor
    func fetch() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let user = try await fetchUserUseCase.execute(userId: userId)
            userName = user.name
            logger.log("Fetched user detail: \(user.name)")
        } catch {
            logger.log("Error: \(error)")
        }
    }
}
