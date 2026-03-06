import SwiftUI

extension EnvironmentValues {
    @Entry var userUseCase: any UserUseCaseProtocol = UserUseCase(apiClient: LiveAPIClient())
    @Entry var logger: any LoggerProtocol = ConsoleLogger()
}
