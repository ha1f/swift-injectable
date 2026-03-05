import SwiftUI
import SwiftInjectable

/// SwiftUI View 内で依存を解決する Property Wrapper
///
/// swift-dependencies と同様に struct プロパティへの直接代入方式を採用。
/// `update()` は `body` 評価前に呼ばれるため、`wrappedValue` 時点で必ず値がセットされている。
@propertyWrapper
public struct Injected<Value: Injectable>: DynamicProperty {
    @Environment(\.container) private var container
    // update() で解決される。body 評価前に必ずセットされる。
    private var resolved: Value?

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
