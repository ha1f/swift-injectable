import SwiftUI

struct UserDetailView: View {
    @Environment(\.userUseCase) var userUseCase
    @Environment(\.logger) var logger
    @State private var userName = ""
    @State private var isLoading = false
    let userId: Int

    var body: some View {
        VStack(spacing: 16) {
            if isLoading {
                ProgressView()
            } else {
                Text(userName)
                    .font(.title)
                Text("ID: \(userId)")
                    .font(.caption)
            }
        }
        .padding()
        .task {
            await fetch()
        }
    }

    @MainActor
    private func fetch() async {
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
