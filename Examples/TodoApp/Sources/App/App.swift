import SwiftInjectable
import SwiftUI
import TodoListFeature
import TodoStatsFeature

@main
struct TodoApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                TodoListView()
                    .toolbar {
                        ToolbarItem(placement: .navigation) {
                            NavigationLink {
                                TodoStatsView()
                            } label: {
                                Image(systemName: "chart.bar")
                            }
                        }
                    }
            }
            .injectAll(AppDependencies())
        }
    }
}
