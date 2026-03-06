import SwiftUI
import SwiftInjectableMacros

struct UserDetailView: View {
    @Injected var viewModel: UserDetailViewModel

    init(userId: Int) {
        _viewModel = Injected { deps in
            UserDetailViewModel(
                userUseCase: deps.userUseCase,
                logger: deps.logger,
                userId: userId
            )
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            if viewModel.isLoading {
                ProgressView()
            } else {
                Text(viewModel.userName)
                    .font(.title)
                Text("ID: \(viewModel.userId)")
                    .font(.caption)
            }
        }
        .padding()
        .task {
            await viewModel.fetch()
        }
    }
}
