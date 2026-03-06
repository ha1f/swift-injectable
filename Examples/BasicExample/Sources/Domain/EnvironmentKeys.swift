import SwiftUI

extension EnvironmentValues {
    @Entry var fetchUserUseCase: any FetchUserUseCaseProtocol = FetchUserUseCase(apiClient: LiveAPIClient())
    @Entry var logger: any LoggerProtocol = ConsoleLogger()
}
