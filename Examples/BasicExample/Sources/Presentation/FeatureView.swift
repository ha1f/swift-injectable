import SwiftUI

public struct FeatureView: View {
    var fetchUser = UseFetchUser()
    var logger = UseLogger()

    public init() {}

    public var body: some View {
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

            NavigationLink("Counter") {
                CounterView()
            }
        }
        .padding()
    }
}
