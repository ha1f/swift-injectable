@propertyWrapper
public struct Inject<Value: Sendable>: Sendable {
    private let _value: Value?

    public var wrappedValue: Value {
        guard let _value else {
            fatalError("@Inject property was not resolved. Ensure the owning type is created via Container.resolve() or the direct injection init.")
        }
        return _value
    }

    public init() {
        self._value = nil
    }

    public init(_ value: Value) {
        self._value = value
    }
}
