import SwiftInjectableMacros

@Dependencies
struct AppDependencies {
    var apiClient: any APIClientProtocol { _apiClient ?? LiveAPIClient() }
    var logger: any LoggerProtocol { _logger ?? ConsoleLogger() }
    var userUseCase: any UserUseCaseProtocol { _userUseCase ?? UserUseCase(apiClient: apiClient) }
}
