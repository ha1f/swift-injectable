import ConsoleLogger
import Domain
import LiveAPIClient
import SwiftInjectable

/// アプリ全体の依存コンテナ。
/// `@Provide(as:)` で登録するインターフェース型を明示し、@Provider が registerAll を生成する。
@MainActor
@Provider
class AppDependencies {
    @Provide(as: (any LoggerProtocol).self)
    lazy var logger = ConsoleLogger()

    @Provide(as: (any APIClientProtocol).self)
    lazy var apiClient = LiveAPIClient()

    @Provide(as: (any UserUseCaseProtocol).self)
    lazy var userUseCase = UserUseCase(apiClient: apiClient)
}
