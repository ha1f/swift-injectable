import Data
import Domain
import Infrastructure
import SwiftInjectable

/// アプリ全体の依存コンテナ
@MainActor
@Provider
class AppDependencies {
    @Provide(as: (any LoggerProtocol).self)
    lazy var logger = ConsoleLogger()

    @Provide(as: (any TodoRepositoryProtocol).self)
    lazy var repository = InMemoryTodoRepository()
}
