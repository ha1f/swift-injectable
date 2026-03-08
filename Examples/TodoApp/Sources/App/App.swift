import SwiftInjectable
import SwiftUI
import TodoFormFeature
import TodoListFeature
import TodoStatsFeature

@main
struct TodoApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                RootView()
            }
            .injectAll(AppDependencies())
        }
    }
}

/// ルート画面: TodoListViewにツールバー（追加・統計）を追加
struct RootView: View {
    var hook = UseTodoListView()

    var body: some View {
        TodoListView()
            .navigationTitle("Todo")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        hook.showForm()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigation) {
                    NavigationLink {
                        TodoStatsView()
                    } label: {
                        Image(systemName: "chart.bar")
                    }
                }
            }
            .sheet(isPresented: hook.binding.isFormPresented) {
                NavigationStack {
                    TodoFormView { title in
                        hook.submitForm(title: title)
                    }
                }
            }
    }
}
