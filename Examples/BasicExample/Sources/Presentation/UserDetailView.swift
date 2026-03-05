import SwiftUI
import SwiftInjectable

struct UserDetailView: View {
    // 追加引数があるため @Injected は使えない。Container から手動で生成する。
    @Environment(\.container) private var container
    @State private var viewModel: UserDetailViewModel?

    let userId: Int

    var body: some View {
        Group {
            if let viewModel {
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
            } else {
                ProgressView()
            }
        }
        .padding()
        .task {
            if viewModel == nil {
                let vm = UserDetailViewModel(container: container, userId: userId)
                viewModel = vm
                await vm.fetch()
            }
        }
    }
}
