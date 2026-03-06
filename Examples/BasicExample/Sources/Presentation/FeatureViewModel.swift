import Foundation
import SwiftInjectableMacros

/// UseCase 経由で依存を使うパターン
@Injectable
@Observable
final class FeatureViewModel {
    @ObservationIgnored @Inject var fetchUserUseCase: any FetchUserUseCaseProtocol
    @ObservationIgnored @Inject var logger: any LoggerProtocol

    var userName: String = ""
    var isLoading: Bool = false

    @MainActor
    func fetch(userId: Int) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let user = try await fetchUserUseCase.execute(userId: userId)
            userName = user.name
            logger.log("Fetched user: \(user.name)")
        } catch {
            logger.log("Error: \(error)")
        }
    }
}
