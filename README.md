# swift-injectable

A lightweight, macro-driven dependency injection library for SwiftUI.

Built on SwiftUI's `Environment` and `DynamicProperty`, SwiftInjectable provides type-safe DI with minimal boilerplate. This package ships two independent libraries:

| Library | Purpose |
|---|---|
| **SwiftInjectable** | DI container, `@Injected` property wrapper, and `withTestInjection` for testing |
| **SwiftHooks** | `@Hook` macro for creating testable `DynamicProperty` structs |

## Requirements

- Swift 6.0+
- iOS 17+ / macOS 14+ / tvOS 17+ / watchOS 10+
- Xcode 16+

## Installation

Add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/ha1f/swift-injectable", from: "0.1.0"),
]
```

Then add the libraries you need. They are independent — use either or both:

```swift
.target(
    name: "YourApp",
    dependencies: [
        .product(name: "SwiftInjectable", package: "swift-injectable"),
        .product(name: "SwiftHooks", package: "swift-injectable"),
    ]
),
```

---

## SwiftInjectable

### 1. Define protocols

```swift
protocol LoggerProtocol: Sendable {
    func log(_ message: String)
}

protocol APIClientProtocol: Sendable {
    func fetchUser(id: Int) async throws -> User
}
```

### 2. Create a dependency container

Use `@Injectable` on a class and `@Provide(as:)` on each property to declare the protocol it fulfills:

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

`@Injectable` generates:
- `registerAll(in:)` — registers each `@Provide`-annotated property into `InjectionStore`
- `InjectableContainer` protocol conformance

### 3. Inject at the root

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

### 4. Resolve with `@Injected`

```swift
struct ContentView: View {
    @Injected var logger: any LoggerProtocol

    var body: some View {
        Button("Log") { logger.log("Hello!") }
    }
}
```

### Default values

Use `@Injected(default:)` to provide a fallback when a dependency is not registered:

```swift
@Injected(default: ConsoleLogger()) var logger: any LoggerProtocol
```

### Injecting individual dependencies

You can also inject dependencies one at a time without a container:

```swift
ContentView()
    .inject(ConsoleLogger() as any LoggerProtocol, as: (any LoggerProtocol).self)
```

---

## SwiftHooks

The `@Hook` macro turns a plain struct into a testable `DynamicProperty`. Stored vars are moved into an `@Observable` storage class held by `@SwiftUI.State`, so mutations work both in SwiftUI views and in unit tests.

### Defining a hook

```swift
@Hook
@MainActor
struct UseFetchUser {
    @Injected var userUseCase: any UserUseCaseProtocol
    @Injected var logger: any LoggerProtocol
    var user: User? = nil
    var isLoading: Bool = false

    func fetch(userId: Int) async {
        isLoading = true
        defer { isLoading = false }
        do {
            user = try await userUseCase.fetch(userId: userId)
            logger.log("Fetched user: \(user?.name ?? "")")
        } catch {
            logger.log("Error: \(error)")
        }
    }
}
```

### Using a hook in a view

```swift
struct FeatureView: View {
    var fetchUser = UseFetchUser()

    var body: some View {
        VStack {
            if fetchUser.isLoading {
                ProgressView()
            } else {
                Text(fetchUser.user?.name ?? "No user")
            }
            Button("Fetch") {
                Task { await fetchUser.fetch(userId: 1) }
            }
        }
    }
}
```

### What `@Hook` generates

Given `var count: Int = 0`, the macro generates:

- `@Observable final class Storage` — holds the stored vars
- `@SwiftUI.State private var hookStorage: Storage` — persists the storage across view updates
- `init(count: Int = 0)` — with default values from your declarations
- `var count: Int { get { hookStorage.count } nonmutating set { hookStorage.count = newValue } }` — computed property delegating to the storage
- `extension: DynamicProperty` — conformance

### Rules

| Declaration | Treatment |
|---|---|
| `var x: T = value` (stored, with type annotation) | Moved to `Storage`, replaced with computed property |
| `var x: T { ... }` (computed) | Left untouched |
| `let x = SomeHook()` | Left untouched (sub-hook, managed by SwiftUI) |
| `@Injected var x` | Left untouched |
| `@Environment`, `@State`, `@Binding`, etc. | Left untouched |
| `func ...` | Left untouched (`nonmutating set` makes mutation work) |

### Constraints

- **Type annotations are required** on stored vars: `var count: Int = 0` (not `var count = 0`). A compile-time error is emitted if the annotation is missing.
- `@Hook` can only be applied to structs.

### Lifecycle (`update()`)

`@Hook` structs can implement `DynamicProperty.update()` for side effects that run before each view body evaluation:

```swift
@Hook
@MainActor
struct UseAutoRefresh {
    @Injected var api: any APIClientProtocol
    var items: [Item] = []
    var needsRefresh: Bool = true

    mutating func update() {
        guard needsRefresh else { return }
        needsRefresh = false
        Task { items = try await api.fetchItems() }
    }
}
```

> **Note:** `update()` is called by SwiftUI only — it does not run in tests. For testable side effects, use explicit methods like `fetch()`.

### Hooks without state

If there are no stored vars, `@Hook` simply adds `DynamicProperty` conformance without generating a `Storage` class:

```swift
@Hook
struct UseCounterView {
    let counter = UseCounter()
    var displayText: String { "Count: \(counter.count)" }
}
```

---

## Testing

### Why `@Hook` is testable

The key insight: `@Hook` stores state in an `@Observable` class (reference type) held by `@SwiftUI.State`. Because the storage is a reference type, mutations are visible even outside a SwiftUI view hierarchy. `@State` preserves the reference, and `@Observable` triggers SwiftUI updates.

### Testing hooks with `withTestInjection`

`withTestInjection` overrides `@Injected` resolution for the duration of the closure, allowing you to test `DynamicProperty` hooks without a SwiftUI view hierarchy:

```swift
@Suite("UseFetchUser")
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
            store.register(mockUseCase, for: (any UserUseCaseProtocol).self)
            store.register(mockLogger, for: (any LoggerProtocol).self)
        }) {
            let hook = UseFetchUser()
            await hook.fetch(userId: 42)

            #expect(hook.user?.name == "Test User 42")
            #expect(hook.isLoading == false)
            #expect(mockUseCase.fetchCallCount == 1)
            #expect(mockLogger.logCallCount == 1)
        }
    }
}
```

`withTestInjection` uses `TaskLocal` internally, so tests can run in parallel without `.serialized`.

### Testing hooks without DI

Hooks that don't use `@Injected` can be tested directly:

```swift
@Test("counter increments")
func counterIncrements() {
    let counter = UseCounter()
    counter.increment()
    #expect(counter.count == 1)
}
```

---

## API Reference

### Macros

| Macro | Library | Description |
|---|---|---|
| `@Injectable` | SwiftInjectable | Generates `registerAll(in:)` and `InjectableContainer` conformance for a class. |
| `@Provide(as: Type.self)` | SwiftInjectable | Marks a property in an `@Injectable` class for registration under the given protocol type. |
| `@Hook` | SwiftHooks | Generates `@Observable` storage, init, computed properties, and `DynamicProperty` conformance for a struct. |

### Property Wrapper

| Type | Library | Description |
|---|---|---|
| `@Injected` | SwiftInjectable | Resolves a dependency by type from the SwiftUI `Environment`. Falls back to `InjectionOverride` in tests. |

### View Modifiers

| Modifier | Description |
|---|---|
| `.injectAll(_:)` | Registers all dependencies from an `InjectableContainer` into the environment. |
| `.inject(_:as:)` | Registers a single dependency by type into the environment. |

### Testing Utilities

| API | Description |
|---|---|
| `withTestInjection(configure:perform:)` | Overrides `@Injected` resolution for the duration of `perform`. Uses `TaskLocal` for safe parallel testing. |
| `InjectionOverride` | `TaskLocal`-based store used by `withTestInjection`. Not intended for direct use. |
| `InjectionStore` | Type-keyed dependency storage. Use `register(_:as:)`, `register(_:for:)`, and `resolve(_:)`. |

---

## How It Works

### Dependency injection flow

1. **Registration** — `.injectAll()` calls `registerAll(in:)` on your container, storing each dependency in an `InjectionStore` keyed by `ObjectIdentifier` of the protocol type.
2. **Propagation** — The `InjectionStore` flows down through SwiftUI's `Environment` via `transformEnvironment`.
3. **Resolution** — `@Injected` reads from `@Environment(\.injectionStore)` and resolves the dependency by type. In tests, `InjectionOverride.current` is checked first.

### `@Hook` macro internals

1. **Member macro** — Generates `Storage` class, `@SwiftUI.State` property, and `init`.
2. **Member attribute macro** — Attaches `@_HookAccessor` to each stored var.
3. **`@_HookAccessor` accessor macro** — Adds `get`/`nonmutating set` accessors that delegate to `hookStorage`, converting the stored var into a computed property.
4. **`@_HookAccessor` peer macro** — Generates a backing stored property required by the `init` accessor.
5. **Extension macro** — Adds `DynamicProperty` conformance.

---

## Example App

See [`Examples/BasicExample`](Examples/BasicExample) for a complete multi-module app demonstrating `@Injectable`, `@Hook`, `@Injected`, and `withTestInjection` working together.

---

## Known Limitations & Roadmap

### Planned Improvements

- **Generic struct support for `@Hook`** — `@Hook struct Foo<T>` does not propagate generic parameters to the generated `Storage` class, causing compile errors. Workaround: avoid generic type parameters in stored vars.
- **Richer lifecycle hooks** — `DynamicProperty.update()` is available but limited (no dependency tracking, no cleanup, not called in tests). A `useEffect`-like API with change detection would be more powerful.

### Design Constraints

- **SwiftUI only** — `@Injected` resolves via SwiftUI `Environment`. It does not work in UIKit or non-UI code.
- **Type annotations required** — `@Hook` stored vars must have explicit type annotations (`var count: Int = 0`, not `var count = 0`) due to Swift macro limitations.

## License

MIT License. See [LICENSE](LICENSE) for details.
