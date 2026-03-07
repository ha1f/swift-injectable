import ConsoleLogger
import Domain
import LiveAPIClient
import SwiftInjectable

/// アプリ全体の依存コンテナ。
/// `lazy var` で依存を定義し、@Injectable が registerAll と init を生成する。
/// テスト時は `AppDependencies(logger: MockLogger())` のように部分的に差し替え可能。
@MainActor
@Injectable
class AppDependencies {
    lazy var logger: any LoggerProtocol = ConsoleLogger()
    lazy var apiClient: any APIClientProtocol = LiveAPIClient()
    lazy var userUseCase: any UserUseCaseProtocol = UserUseCase(apiClient: apiClient)
}
