import SwiftUI

struct UseFetchUser: DynamicProperty {
    @Environment(\.userUseCase) private var useCase
    @Environment(\.logger) private var logger
    @State var user: User?
    @State var isLoading = false
    @State var error: Error?

    @MainActor
    func fetch(userId: Int) async {
        isLoading = true
        defer { isLoading = false }
        do {
            user = try await useCase.execute(userId: userId)
            logger.log("Fetched user: \(user?.name ?? "")")
        } catch {
            self.error = error
            logger.log("Error: \(error)")
        }
    }
}
