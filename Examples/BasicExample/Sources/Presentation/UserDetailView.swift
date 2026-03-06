import SwiftUI

struct UserDetailView: View {
    var fetchUser = UseFetchUser()
    var logger = UseLogger()
    let userId: Int

    var body: some View {
        VStack(spacing: 16) {
            if fetchUser.isLoading {
                ProgressView()
            } else {
                Text(fetchUser.user?.name ?? "")
                    .font(.title)
                Text("ID: \(userId)")
                    .font(.caption)
            }
        }
        .padding()
        .task {
            await fetchUser.fetch(userId: userId)
        }
    }
}
