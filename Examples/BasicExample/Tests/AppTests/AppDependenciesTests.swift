import ConsoleLogger
import Domain
import LiveAPIClient
import SwiftInjectable
import Testing

@Suite("AppDependencies 相当のテスト")
struct AppDependenciesTests {

    @Test("InjectionStore に依存を登録して解決できる")
    func registerAndResolve() {
        var store = InjectionStore()
        let logger = ConsoleLogger()
        store.register(logger, for: (any LoggerProtocol).self)

        let resolved = store.resolve((any LoggerProtocol).self)
        #expect(resolved != nil)
    }

    @Test("未登録の型は nil を返す")
    func resolveUnregistered() {
        let store = InjectionStore()
        let resolved = store.resolve((any LoggerProtocol).self)
        #expect(resolved == nil)
    }

    @Test("複数の型を個別に登録・解決できる")
    func registerMultiple() {
        var store = InjectionStore()
        store.register(ConsoleLogger(), for: (any LoggerProtocol).self)
        store.register(LiveAPIClient(), for: (any APIClientProtocol).self)

        #expect(store.resolve((any LoggerProtocol).self) != nil)
        #expect(store.resolve((any APIClientProtocol).self) != nil)
    }

    @Test("依存チェーン: UserUseCase が apiClient を使える")
    func dependencyChaining() async throws {
        let apiClient = LiveAPIClient()
        let useCase = UserUseCase(apiClient: apiClient)

        var store = InjectionStore()
        store.register(apiClient, for: (any APIClientProtocol).self)
        store.register(useCase, for: (any UserUseCaseProtocol).self)

        let resolved = store.resolve((any UserUseCaseProtocol).self)
        #expect(resolved != nil)

        let user = try await resolved!.fetch(userId: 1)
        #expect(user.id == 1)
    }
}
