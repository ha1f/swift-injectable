import SwiftUI
import SwiftInjectable

/// SwiftUI View 内で依存を解決する Property Wrapper
///
/// `@State` で保持するため、View 再構築でも ViewModel の寿命が維持される。
/// `update()` は `body` 評価前に呼ばれるため、`wrappedValue` 時点で必ず値がセットされている。
@propertyWrapper
public struct Injected<Value: Injectable>: DynamicProperty {
    @Environment(\.container) private var container
    @State private var resolved: Value?

    public var wrappedValue: Value {
        guard let resolved else {
            fatalError("@Injected<\(Value.self)> was accessed before update(). This should not happen.")
        }
        return resolved
    }

    public init() {}

    public mutating func update() {
        if resolved == nil {
            resolved = container.resolve(Value.self)
        }
    }
}
