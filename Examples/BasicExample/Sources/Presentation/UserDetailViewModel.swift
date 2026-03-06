import Foundation
import SwiftInjectableMacros

@Injectable
@Observable
final class UserDetailViewModel {
    @Dependency let userUseCase: any UserUseCaseProtocol
    @Dependency let logger: any LoggerProtocol
    let userId: Int

    var userName: String = ""
    var isLoading: Bool = false

    @MainActor
    func fetch() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let user = try await userUseCase.execute(userId: userId)
            userName = user.name
            logger.log("Fetched user detail: \(user.name)")
        } catch {
            logger.log("Error: \(error)")
        }
    }
}
