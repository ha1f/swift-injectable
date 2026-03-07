import ConsoleLogger
import Domain
import LiveAPIClient
import SwiftInjectable

/// アプリ全体の依存コンテナ。
/// `@Provide(as:)` で登録するインターフェース型を明示し、@Injectable が registerAll と init を生成する。
/// テスト時は `AppDependencies(logger: MockLogger())` のように部分的に差し替え可能。
@MainActor
@Injectable
class AppDependencies {
    @Provide(as: (any LoggerProtocol).self)
    lazy var logger = ConsoleLogger()

    @Provide(as: (any APIClientProtocol).self)
    lazy var apiClient = LiveAPIClient()

    @Provide(as: (any UserUseCaseProtocol).self)
    lazy var userUseCase = UserUseCase(apiClient: apiClient)
}
