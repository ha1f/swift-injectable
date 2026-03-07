# SwiftInjectable

A lightweight, type-safe dependency injection library for SwiftUI, powered by Swift Macros.

SwiftInjectable leverages SwiftUI's `Environment` system and Swift Macros to provide a clean, declarative DI experience with minimal boilerplate. Define your dependencies in a container, inject them at the root, and resolve them anywhere in your view hierarchy.

This package also includes **SwiftHooks** — a companion library that provides the `@Hook` macro for creating testable, React-style hooks with `DynamicProperty`.

## Features

- **Macro-driven** - `@Injectable`, `@Provide(as:)`, and `@Hook` generate boilerplate automatically
- **SwiftUI-native** - Built on `Environment` and `DynamicProperty`, not a custom runtime
- **Type-safe** - Dependencies are keyed by protocol type; missing dependencies are caught immediately
- **Testable** - `withTestInjection` and `@Hook`'s `@Observable` storage work outside SwiftUI
- **Minimal API surface** - Just a few concepts: `@Injectable`, `@Provide`, `@Injected`, `.injectAll()`, and `@Hook`

## Requirements

- Swift 6.0+
- iOS 17+ / macOS 14+ / tvOS 17+ / watchOS 10+
- Xcode 16+

## Installation

### Swift Package Manager

Add the following to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/ha1f/swift-injectable", from: "0.1.0"),
]
```

Then add the libraries you need:

```swift
.target(
    name: "YourApp",
    dependencies: [
        .product(name: "SwiftInjectable", package: "swift-injectable"),
        .product(name: "SwiftHooks", package: "swift-injectable"),
    ]
),
```

`SwiftInjectable` and `SwiftHooks` are independent — you can use either or both.

## Quick Start

### 1. Define protocols for your dependencies

```swift
protocol LoggerProtocol: Sendable {
    func log(_ message: String)
}

protocol APIClientProtocol: Sendable {
    func fetchUser(id: Int) async throws -> User
}
```

### 2. Create a dependency container

Use `@Injectable` on a class and `@Provide(as:)` on each property to declare which protocol it fulfills:

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

The `@Injectable` macro automatically generates:
- A `registerAll(in:)` method that registers each `@Provide`-annotated property into `InjectionStore`
- Conformance to the `InjectableContainer` protocol

### 3. Inject at the root of your view hierarchy

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .injectAll(AppDependencies())
        }
    }
}
```

### 4. Resolve dependencies with `@Injected`

```swift
struct ContentView: View {
    @Injected var logger: any LoggerProtocol
    @Injected var apiClient: any APIClientProtocol

    var body: some View {
        Button("Log") {
            logger.log("Hello!")
        }
    }
}
```

## SwiftHooks — `@Hook` Macro

The `@Hook` macro turns a plain struct into a testable `DynamicProperty`. Stored vars are automatically moved into an `@Observable` storage class held by `@SwiftUI.State`, so mutations work both in SwiftUI and in tests.

```swift
@Hook
@MainActor
struct UseFetchUser {
    @Injected var userUseCase: any UserUseCaseProtocol
    @Injected var logger: any LoggerProtocol
    var user: User? = nil
    var isLoading: Bool = false
    var error: (any Error)? = nil

    func fetch(userId: Int) async {
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

Use it in a View like a built-in property:

```swift
struct FeatureView: View {
    var fetchUser = UseFetchUser()

    var body: some View {
        VStack {
            if fetchUser.isLoading {
                ProgressView()
            } else {
                Text(fetchUser.user?.name ?? "")
            }
            Button("Fetch") {
                Task { await fetchUser.fetch(userId: 1) }
            }
        }
    }
}
```

### What `@Hook` generates

- An `@Observable final class Storage` with your stored vars
- A `@SwiftUI.State` property to hold the storage
- An `init` with default values from your declarations
- Computed properties with `nonmutating set` that delegate to the storage
- `DynamicProperty` conformance

### Constraints

- Stored vars require **type annotations**: `var count: Int = 0` (not `var count = 0`)
- `@Injected`, `@Environment`, `@State`, `@Binding`, `@ObservedObject`, `@StateObject` properties are left untouched
- `let` properties and computed properties are left untouched
- `@Hook` can only be applied to structs

### Hooks without state

If a hook has no stored vars (only sub-hooks, computed properties, etc.), `@Hook` simply adds `DynamicProperty` conformance without generating a `Storage` class:

```swift
@Hook
struct UseCounterView {
    let counter = UseCounter()
    var displayText: String { "Count: \(counter.count)" }
}
```

## Injecting Individual Dependencies

You can also inject dependencies one at a time without a container:

```swift
ContentView()
    .inject(ConsoleLogger() as any LoggerProtocol, as: (any LoggerProtocol).self)
    .inject(LiveAPIClient() as any APIClientProtocol, as: (any APIClientProtocol).self)
```

## Testing

### Testing DynamicProperty hooks

Use `withTestInjection` to override `@Injected` dependencies in tests without needing a SwiftUI view hierarchy:

```swift
@Suite(.serialized)
@MainActor
struct UseFetchUserTests {

    @Test
    func fetchSuccess() async {
        let mockUseCase = UserUseCaseProtocolMock()
        mockUseCase.fetchHandler = { userId in
            User(id: userId, name: "Test User \(userId)")
        }
        let mockLogger = LoggerProtocolMock()
        mockLogger.logHandler = { _ in }

        await withTestInjection(configure: { store in
            store.register(
                mockUseCase as any UserUseCaseProtocol,
                as: (any UserUseCaseProtocol).self
            )
            store.register(
                mockLogger as any LoggerProtocol,
                as: (any LoggerProtocol).self
            )
        }) {
            var fetchUser = UseFetchUser()
            await fetchUser.fetch(userId: 42)

            #expect(mockUseCase.fetchCallCount == 1)
            #expect(mockLogger.logCallCount == 1)
        }
    }
}
```

> **Note:** Test suites using `withTestInjection` should be marked with `.serialized` to avoid race conditions on the shared `InjectionOverride` store.

## API Reference

### Macros

| Macro | Library | Description |
|---|---|---|
| `@Injectable` | SwiftInjectable | Attached to a class. Generates `registerAll(in:)` and `InjectableContainer` conformance. |
| `@Provide(as: Type.self)` | SwiftInjectable | Attached to a property inside an `@Injectable` class. Declares the protocol type to register. |
| `@Hook` | SwiftHooks | Attached to a struct. Generates `@Observable` storage, init, and `DynamicProperty` conformance. |

### Property Wrapper

| Type | Description |
|---|---|
| `@Injected` | Resolves a dependency from the SwiftUI `Environment` by type. Conforms to `DynamicProperty`. |

### View Modifiers

| Modifier | Description |
|---|---|
| `.injectAll(_:)` | Registers all dependencies from an `InjectableContainer` into the environment. |
| `.inject(_:as:)` | Registers a single dependency by type into the environment. |

### Testing

| API | Description |
|---|---|
| `withTestInjection(configure:perform:)` | Overrides `@Injected` resolution for the duration of `perform`. |
| `InjectionOverride` | Static store used by `withTestInjection`. Not intended for direct use. |
| `InjectionStore` | Type-keyed storage. Use `register(_:as:)` and `resolve(_:)` to manage dependencies. |

## How It Works

SwiftInjectable stores dependencies in an `InjectionStore` inside SwiftUI's `EnvironmentValues`. The flow is:

1. **Registration** - `.injectAll()` calls `registerAll(in:)` on your container, which stores each dependency in an `InjectionStore` keyed by `ObjectIdentifier` of the protocol type.
2. **Propagation** - The `InjectionStore` is passed down through SwiftUI's `Environment` via `transformEnvironment`.
3. **Resolution** - `@Injected` reads from `@Environment(\.injectionStore)` and resolves the dependency by type. In tests, `InjectionOverride.current` is checked first.

## Example App

See the [`Examples/BasicExample`](Examples/BasicExample) directory for a complete multi-module app demonstrating:

- **Domain** - Protocols and models (no dependencies)
- **ConsoleLogger** - `LoggerProtocol` implementation
- **LiveAPIClient** - `APIClientProtocol` implementation
- **Presentation** - Views and `@Hook` hooks (depends on Domain + SwiftInjectable + SwiftHooks)
- **App** - Composition root with `@Injectable` container

```
Examples/BasicExample/
├── Sources/
│   ├── Domain/           # Protocols, models, use cases
│   ├── ConsoleLogger/    # LoggerProtocol implementation
│   ├── LiveAPIClient/    # APIClientProtocol implementation
│   ├── Presentation/     # Views and hooks (@Injected)
│   └── App/              # @Injectable container + App entry point
└── Tests/
    ├── DomainTests/
    └── PresentationTests/ # withTestInjection tests
```

## License

MIT License. See [LICENSE](LICENSE) for details.
