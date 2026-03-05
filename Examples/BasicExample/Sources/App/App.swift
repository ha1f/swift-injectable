import SwiftUI
import SwiftInjectable

let appContainer = Container {
    $0.singleton(APIClientProtocol.self) { _ in LiveAPIClient() }
    $0.singleton(LoggerProtocol.self) { _ in ConsoleLogger() }
}

@main
struct BasicExampleApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                FeatureView()
            }
            .environment(\.container, appContainer)
        }
    }
}
