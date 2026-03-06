import SwiftUI
import SwiftInjectable

@propertyWrapper
public struct Injected<Value: Injectable>: DynamicProperty
    where Value.Dependencies: DependenciesProtocol,
          Value.Dependencies.Target == Value
{
    private var deps = Value.Dependencies()
    @State private var object: Value?
    private let factory: (Value.Dependencies) -> Value

    public var wrappedValue: Value {
        guard let object else {
            fatalError("@Injected<\(Value.self)> was accessed before update().")
        }
        return object
    }

    public init(_ factory: @escaping (Value.Dependencies) -> Value) {
        self.factory = factory
    }

    public mutating func update() {
        if object == nil {
            object = factory(deps.resolve())
        }
    }
}

// MARK: - 追加パラメータなしの場合、closure省略可能

extension Injected where Value: AutoInjectable {
    public init() {
        self.init { deps in Value(deps: deps) }
    }
}
