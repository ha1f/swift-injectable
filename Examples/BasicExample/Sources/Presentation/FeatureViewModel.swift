import Foundation
import SwiftInjectableMacros

@Injectable
@Observable
final class FeatureViewModel {
    @ObservationIgnored @Inject var apiClient: any APIClientProtocol
    @ObservationIgnored @Inject var logger: any LoggerProtocol

    var userName: String = ""
    var isLoading: Bool = false

    @MainActor
    func fetch(userId: Int) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let user = try await apiClient.fetchUser(id: userId)
            userName = user.name
            logger.log("Fetched user: \(user.name)")
        } catch {
            logger.log("Error: \(error)")
        }
    }
}
