# BasicExample

A multi-module SwiftUI app demonstrating **SwiftInjectable** and **SwiftHooks** working together.

## Architecture

```
Sources/
├── Domain/           # Protocols, models, use cases (no framework dependencies)
├── ConsoleLogger/    # LoggerProtocol implementation
├── LiveAPIClient/    # APIClientProtocol implementation
├── Presentation/     # @Hook hooks with @Injected (depends on Domain + SwiftInjectable + SwiftHooks)
└── App/              # @Injectable container + SwiftUI App entry point
Tests/
├── DomainTests/      # UseCase unit tests
├── PresentationTests/ # Hook tests with withTestInjection
└── AppTests/          # InjectionStore integration tests
```

## Key Concepts

### Dependency Container (`App/AppDependencies.swift`)

`@Injectable` + `@Provide(as:)` define a composition root. The `@Injectable` macro generates `registerAll(in:)` which registers each dependency by its protocol type.

```swift
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
```

Dependencies are injected at the app root with `.injectAll()`:

```swift
@main
struct BasicExampleApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                FeatureView()
            }
            .injectAll(AppDependencies())
        }
    }
}
```

### Hooks (`Presentation/UseFetchUser.swift`)

`@Hook` eliminates the boilerplate of manually conforming to `DynamicProperty`, wrapping state in `@State`, and writing `init()`. Stored vars with type annotations are automatically managed:

```swift
@Hook
@MainActor
public struct UseFetchUser {
    @Injected var userUseCase: any UserUseCaseProtocol
    @Injected var logger: any LoggerProtocol
    public var user: User? = nil
    public var isLoading: Bool = false
    public var error: (any Error)? = nil

    public func fetch(userId: Int) async {
        isLoading = true
        defer { isLoading = false }
        do {
            user = try await userUseCase.fetch(userId: userId)
            logger.log("Fetched user: \(user?.name ?? "")")
        } catch {
            self.error = error
            logger.log("Error: \(error)")
        }
    }
}
```

Hooks are used in views like built-in properties:

```swift
struct FeatureView: View {
    var fetchUser = UseFetchUser()

    var body: some View {
        VStack {
            if fetchUser.isLoading { ProgressView() }
            else { Text(fetchUser.user?.name ?? "") }
            Button("Fetch User") {
                Task { await fetchUser.fetch(userId: 1) }
            }
        }
    }
}
```

### Testing (`Tests/PresentationTests/UseFetchUserTests.swift`)

`withTestInjection` overrides `@Injected` resolution without a SwiftUI view hierarchy. Because `@Hook` uses `@Observable` class storage (reference type), state mutations are visible in tests.

```swift
@Suite("UseFetchUser", .serialized)
@MainActor
struct UseFetchUserTests {

    @Test("fetches user successfully")
    func fetchSuccess() async {
        let mockUseCase = UserUseCaseProtocolMock()
        mockUseCase.fetchHandler = { userId in
            User(id: userId, name: "Test User \(userId)")
        }
        let mockLogger = LoggerProtocolMock()
        mockLogger.logHandler = { _ in }

        await withTestInjection(configure: { store in
            store.register(mockUseCase as any UserUseCaseProtocol,
                           as: (any UserUseCaseProtocol).self)
            store.register(mockLogger as any LoggerProtocol,
                           as: (any LoggerProtocol).self)
        }) {
            let hook = UseFetchUser()
            await hook.fetch(userId: 42)

            #expect(mockUseCase.fetchCallCount == 1)
            #expect(mockLogger.logCallCount == 1)
        }
    }

    @Test("logs error on fetch failure")
    func fetchFailure() async {
        let mockUseCase = UserUseCaseProtocolMock()
        mockUseCase.fetchHandler = { (_: Int) in
            throw URLError(.notConnectedToInternet)
        }
        let mockLogger = LoggerProtocolMock()
        mockLogger.logHandler = { _ in }

        await withTestInjection(configure: { store in
            store.register(mockUseCase as any UserUseCaseProtocol,
                           as: (any UserUseCaseProtocol).self)
            store.register(mockLogger as any LoggerProtocol,
                           as: (any LoggerProtocol).self)
        }) {
            let hook = UseFetchUser()
            await hook.fetch(userId: 1)

            #expect(mockUseCase.fetchCallCount == 1)
            #expect(mockLogger.logCallCount == 1)  // error is logged
        }
    }
}
```

> **Note:** Test suites using `withTestInjection` must use `.serialized` to avoid race conditions on the shared `InjectionOverride` store.

## Running

```bash
# Build
swift build

# Test
swift test
```
