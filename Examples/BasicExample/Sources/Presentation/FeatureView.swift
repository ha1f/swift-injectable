import SwiftUI

struct FeatureView: View {
    @Environment(\.userUseCase) var userUseCase
    @Environment(\.logger) var logger
    @State private var userName = ""
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 16) {
            if isLoading {
                ProgressView()
            } else {
                Text(userName)
                    .font(.title)
            }

            Button("Fetch User") {
                Task {
                    await fetch(userId: 1)
                }
            }

            NavigationLink("User Detail") {
                UserDetailView(userId: 42)
            }
        }
        .padding()
    }

    @MainActor
    private func fetch(userId: Int) async {
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
