import Domain
import SwiftHooks
import SwiftInjectable
import SwiftUI

@Hook
@MainActor
public struct UseFetchUser {
    @Injected var userUseCase: any UserUseCaseProtocol
    @Injected var logger: any LoggerProtocol
    public var user: User? = nil
    public var isLoading: Bool = false
    public var error: (any Error)? = nil

    public func fetch(userId: Int) async {
        isLoading = true
        defer { isLoading = false }
        do {
            user = try await userUseCase.fetch(userId: userId)
            logger.log("Fetched user: \(user?.name ?? "")")
        } catch {
            self.error = error
            logger.log("Error: \(error)")
        }
    }
}
