import SwiftHooks
import SwiftUI

/// UseCounterの状態を表示用に変換するhook（hook合成の例）
@Hook
@MainActor
public struct UseCounterView {
    public let counter = UseCounter()

    public init() {}

    public var displayText: String {
        "Count: \(counter.count)"
    }

    public var displayColor: Color {
        if counter.count > 0 {
            .green
        } else if counter.count < 0 {
            .red
        } else {
            .primary
        }
    }
}
