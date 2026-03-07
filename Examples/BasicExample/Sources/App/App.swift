import SwiftUI

@main
struct BasicExampleApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                FeatureView()
            }
            .inject(AppContainer())
        }
    }
}
