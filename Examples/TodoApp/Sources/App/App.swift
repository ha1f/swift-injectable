import Presentation
import SwiftInjectable
import SwiftUI

@main
struct TodoApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                TodoListView()
            }
            .injectAll(AppDependencies())
        }
    }
}
