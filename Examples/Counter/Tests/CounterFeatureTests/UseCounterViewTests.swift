import CounterFeature
import SwiftUI
import Testing

@Suite("UseCounterView")
@MainActor
struct UseCounterViewTests {
    @Test("初期状態のテキストと色")
    func initialState() {
        let view = UseCounterView()
        #expect(view.displayText == "Count: 0")
        #expect(view.displayColor == .primary)
    }

    @Test("正の値で緑色")
    func positiveCount() {
        let view = UseCounterView()
        view.counter.increment()
        #expect(view.displayText == "Count: 1")
        #expect(view.displayColor == .green)
    }

    @Test("負の値で赤色")
    func negativeCount() {
        let view = UseCounterView()
        view.counter.decrement()
        #expect(view.displayText == "Count: -1")
        #expect(view.displayColor == .red)
    }
}
