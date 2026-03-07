# BasicExample

A multi-module SwiftUI app demonstrating **SwiftInjectable** and **SwiftHooks** working together.

For API details and usage patterns, see the [root README](../../README.md).

## Architecture

```
Sources/
├── Domain/           # Protocols, models, use cases (no framework dependencies)
├── ConsoleLogger/    # LoggerProtocol implementation
├── LiveAPIClient/    # APIClientProtocol implementation
├── Presentation/     # @Hook hooks with @Injected + CounterView (depends on Domain + SwiftInjectable + SwiftHooks)
└── App/              # @Provider container + SwiftUI App entry point
Tests/
├── DomainTests/       # UseCase unit tests
├── PresentationTests/ # Hook tests (UseCounter, UseCounterView, UseFetchUser)
└── AppTests/          # InjectionStore integration tests
```

## What This Example Demonstrates

### DI with `@Provider` + `@Injected`
- `App/AppDependencies.swift` — composition root using `@Provider` and `@Provide(as:)`
- `App/App.swift` — injects dependencies at the root with `.injectAll()`
- `Presentation/UseFetchUser.swift` — resolves dependencies with `@Injected`

### Hooks with `@Hook`
- `Presentation/UseCounter.swift` — stateful hook (counter with increment/decrement/reset)
- `Presentation/UseCounterView.swift` — hook composition (UseCounterView wraps UseCounter, adds display logic)
- `Presentation/UseLogger.swift` — hook with `@Injected` dependency

### Testing
- `PresentationTests/UseCounterTests.swift` — testing hooks without DI (direct instantiation)
- `PresentationTests/UseCounterViewTests.swift` — testing composed hooks
- `PresentationTests/UseFetchUserTests.swift` — testing hooks with DI via `withTestInjection`

## Running

```bash
# Build
swift build

# Test
swift test
```
