import Domain
import SwiftInjectable
import SwiftUI

@MainActor
public struct UseFetchUser: DynamicProperty {
    @Inject var userUseCase: any UserUseCaseProtocol
    @Inject var logger: any LoggerProtocol
    @State public var user: User?
    @State public var isLoading = false
    @State public var error: Error?

    public init() {}

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
