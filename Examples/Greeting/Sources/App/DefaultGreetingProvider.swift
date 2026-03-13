import Domain

struct DefaultGreetingProvider: GreetingProviderProtocol {
    func greeting(for name: String) -> String {
        "Hello, \(name)!"
    }
}
