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
    var todoList = UseTodoList()
    @State private var showingForm = false

    var body: some View {
        TodoListView()
            .navigationTitle("Todo")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingForm = true
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
            .sheet(isPresented: $showingForm) {
                NavigationStack {
                    TodoFormView { title in
                        showingForm = false
                        Task {
                            await todoList.add(title: title)
                        }
                    }
                }
            }
    }
}
