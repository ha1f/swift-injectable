import Domain
import SwiftInjectable

@MainActor
@Provider
class AppDependencies {
    @Provide(as: (any GreetingProviderProtocol).self)
    lazy var greetingProvider = DefaultGreetingProvider()
}
