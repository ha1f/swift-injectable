import SwiftUI
import SwiftInjectableMacros

struct UseFetchUser: DynamicProperty {
    @Deps var deps: AppContainer
    @State var user: User?
    @State var isLoading = false
    @State var error: Error?

    @MainActor
    func fetch(userId: Int) async {
        isLoading = true
        defer { isLoading = false }
        do {
            user = try await deps.userUseCase.execute(userId: userId)
            deps.logger.log("Fetched user: \(user?.name ?? "")")
        } catch {
            self.error = error
            deps.logger.log("Error: \(error)")
        }
    }
}
