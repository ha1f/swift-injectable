import Foundation
import SwiftInjectableMacros

@Injectable
@Observable
final class FeatureViewModel {
    @Dependency let userUseCase: any UserUseCaseProtocol
    @Dependency let logger: any LoggerProtocol

    var userName: String = ""
    var isLoading: Bool = false

    @MainActor
    func fetch(userId: Int) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let user = try await userUseCase.execute(userId: userId)
            userName = user.name
            logger.log("Fetched user: \(user.name)")
        } catch {
            logger.log("Error: \(error)")
        }
    }
}
