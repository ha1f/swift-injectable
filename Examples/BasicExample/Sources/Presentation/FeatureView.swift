import SwiftUI
import SwiftInjectableMacros

struct FeatureView: View {
    @Injected() var viewModel: FeatureViewModel

    var body: some View {
        VStack(spacing: 16) {
            if viewModel.isLoading {
                ProgressView()
            } else {
                Text(viewModel.userName)
                    .font(.title)
            }

            Button("Fetch User") {
                Task {
                    await viewModel.fetch(userId: 1)
                }
            }

            NavigationLink("User Detail (追加引数パターン)") {
                UserDetailView(userId: 42)
            }
        }
        .padding()
    }
}
