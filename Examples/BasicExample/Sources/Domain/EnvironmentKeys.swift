import SwiftInjectableMacros

@Dependencies
struct AppDependencies {
    var userUseCase: any UserUseCaseProtocol = UserUseCase(apiClient: LiveAPIClient())
    var logger: any LoggerProtocol = ConsoleLogger()
}
