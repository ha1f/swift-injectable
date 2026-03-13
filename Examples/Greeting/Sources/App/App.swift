import GreetingFeature
import SwiftInjectable
import SwiftUI

@main
struct GreetingApp: App {
    var body: some Scene {
        WindowGroup {
            GreetingView()
                .injectAll(AppDependencies())
        }
    }
}
