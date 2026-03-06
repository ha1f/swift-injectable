import SwiftUI
import SwiftInjectableMacros

extension EnvironmentValues {
    @Entry var userUseCase: any UserUseCaseProtocol = UserUseCase(apiClient: LiveAPIClient())
    @Entry var logger: any LoggerProtocol = ConsoleLogger()
}

@Dependencies
struct AppDependencies {
    var userUseCase: any UserUseCaseProtocol = UserUseCase(apiClient: LiveAPIClient())
    var logger: any LoggerProtocol = ConsoleLogger()
}
