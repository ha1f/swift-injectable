import Dependencies

/// swift-dependencies 用の DependencyKey 定義
private enum GreetingProviderKey: DependencyKey {
    static let liveValue: any GreetingProviderProtocol = DefaultGreetingProvider()
}

extension DependencyValues {
    public var greetingProvider: any GreetingProviderProtocol {
        get { self[GreetingProviderKey.self] }
        set { self[GreetingProviderKey.self] = newValue }
    }
}

private struct DefaultGreetingProvider: GreetingProviderProtocol {
    func greeting(for name: String) -> String {
        "Hello, \(name)!"
    }
}
