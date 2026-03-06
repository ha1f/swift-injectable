import SwiftUI

struct FeatureView: View {
    var fetchUser = UseFetchUser()

    var body: some View {
        VStack(spacing: 16) {
            if fetchUser.isLoading {
                ProgressView()
            } else {
                Text(fetchUser.user?.name ?? "")
                    .font(.title)
            }

            Button("Fetch User") {
                Task {
                    await fetchUser.fetch(userId: 1)
                }
            }

            NavigationLink("User Detail") {
                UserDetailView(userId: 42)
            }
        }
        .padding()
    }
}
