import SwiftHooks
import SwiftUI

/// カウンターの状態と操作を提供するhook
@Hook
@MainActor
public struct UseCounter {
    @HookState public var count: Int = 0

    public func increment() {
        count += 1
    }

    public func decrement() {
        count -= 1
    }

    public func reset() {
        count = 0
    }
}
