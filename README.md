# swift-injectable

A lightweight, macro-driven dependency injection library for SwiftUI.

Built on SwiftUI's `Environment` and `DynamicProperty`, SwiftInjectable provides type-safe DI with minimal boilerplate. This package ships three independent libraries:

| Library | Purpose | README |
|---|---|---|
| **SwiftInjectable** | DI container, `@Injected` property wrapper, and `withTestInjection` for testing | [Sources/SwiftInjectable](Sources/SwiftInjectable/README.md) |
| **SwiftHooks** | `@Hook` macro for creating testable `DynamicProperty` structs | [Sources/SwiftHooks](Sources/SwiftHooks/README.md) |
| **SwiftHooksQuery** | Apollo-style query cache (`UseQuery`, `QueryCache`) for server-state management | [Sources/SwiftHooksQuery](Sources/SwiftHooksQuery/README.md) |

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

Then add the libraries you need. They are independent — use any combination:

```swift
.target(
    name: "YourApp",
    dependencies: [
        .product(name: "SwiftInjectable", package: "swift-injectable"),
        .product(name: "SwiftHooks", package: "swift-injectable"),
        .product(name: "SwiftHooksQuery", package: "swift-injectable"),
    ]
),
```

---

## Quick Start

### DI with `@Injected`

```swift
// 1. Define protocols
protocol LoggerProtocol: Sendable {
    func log(_ message: String)
}

// 2. Create a dependency container
@MainActor
@Provider
class AppDependencies {
    @Provide(as: (any LoggerProtocol).self)
    lazy var logger = ConsoleLogger()
}

// 3. Inject at the root
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .injectAll(AppDependencies())
        }
    }
}

// 4. Resolve with @Injected
struct ContentView: View {
    @Injected var logger: any LoggerProtocol

    var body: some View {
        Button("Log") { logger.log("Hello!") }
    }
}
```

### Hooks with `@Hook`

```swift
@Hook
@MainActor
struct UseCounter {
    var count: Int = 0
    func increment() { count += 1 }
}

struct CounterView: View {
    var counter = UseCounter()
    var body: some View {
        Button("Count: \(counter.count)") { counter.increment() }
    }
}
```

### Server-state with `UseQuery`

```swift
@Hook
@MainActor
struct UseTodosQuery {
    @Injected var repository: any TodoRepositoryProtocol
    let query = UseQuery(\.todos, cachePolicy: .cacheFirst)

    func fetch() async {
        await query.fetch { try await repository.fetchAll() }
    }
}
```

See each library's README for full documentation.

---

## Testing

`withTestInjection` overrides `@Injected` resolution for the duration of the closure. Uses `TaskLocal` internally, so tests can run in parallel without `.serialized`:

```swift
@Test("fetches user successfully")
func fetchSuccess() async {
    await withTestInjection(configure: { store in
        store.register(mockUseCase, for: (any UserUseCaseProtocol).self)
    }) {
        let hook = UseFetchUser()
        await hook.fetch(userId: 42)
        #expect(hook.user?.name == "Test User 42")
    }
}
```

Hooks without `@Injected` can be tested directly:

```swift
@Test("counter increments")
func counterIncrements() {
    let counter = UseCounter()
    counter.increment()
    #expect(counter.count == 1)
}
```

---

## Example Apps

| Example | Description |
|---|---|
| [`Examples/BasicExample`](Examples/BasicExample) | Simple multi-module app — counter hooks, user fetch with DI |
| [`Examples/TodoApp`](Examples/TodoApp) | Feature-module app — CRUD, filtering, hook composition, test helpers |

---

## Known Limitations & Roadmap

### Planned Improvements

- **Richer lifecycle hooks** — `DynamicProperty.update()` is available but limited (no dependency tracking, no cleanup, not called in tests). A `useEffect`-like API with change detection would be more powerful.

### Design Constraints

- **SwiftUI only** — `@Injected` resolves via SwiftUI `Environment`. It does not work in UIKit or non-UI code.
- **Type annotations required** — `@Hook` stored vars must have explicit type annotations (`var count: Int = 0`, not `var count = 0`) due to Swift macro limitations.

## License

MIT License. See [LICENSE](LICENSE) for details.
