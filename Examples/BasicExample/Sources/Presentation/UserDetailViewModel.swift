import Foundation
import SwiftInjectableMacros

/// 追加引数パターンの例。userId は外から渡す。
/// @Injectable が init(container:, userId:) を生成し、Injectable 準拠は生成しない。
@Injectable
@Observable
final class UserDetailViewModel {
    @ObservationIgnored @Inject var apiClient: any APIClientProtocol
    @ObservationIgnored @Inject var logger: any LoggerProtocol

    let userId: Int

    var userName: String = ""
    var isLoading: Bool = false

    @MainActor
    func fetch() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let user = try await apiClient.fetchUser(id: userId)
            userName = user.name
            logger.log("Fetched user detail: \(user.name)")
        } catch {
            logger.log("Error: \(error)")
        }
    }
}
