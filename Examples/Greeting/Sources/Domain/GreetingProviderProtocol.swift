import Mockable

@Mockable
public protocol GreetingProviderProtocol: Sendable {
    func greeting(for name: String) -> String
}
