import SwiftUI
import SwiftInjectable

let appContainer = Container {
    $0.singleton(APIClientProtocol.self) { _ in LiveAPIClient() }
    $0.singleton(LoggerProtocol.self) { _ in ConsoleLogger() }
    $0.singleton(FetchUserUseCaseProtocol.self) { container in
        FetchUserUseCase(apiClient: container.resolve(APIClientProtocol.self))
    }
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
