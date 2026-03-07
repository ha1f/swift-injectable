import SwiftInjectableMacros

@Dependencies
class AppContainer {
    func createApiClient() -> any APIClientProtocol { LiveAPIClient() }
    func createLogger() -> any LoggerProtocol { ConsoleLogger() }
    func createUserUseCase() -> any UserUseCaseProtocol { UserUseCase(apiClient: apiClient) }
}
