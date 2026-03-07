import Presentation
import SwiftInjectable
import SwiftUI

@main
struct BasicExampleApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                FeatureView()
            }
            .injectAll(AppDependencies())
        }
    }
}
