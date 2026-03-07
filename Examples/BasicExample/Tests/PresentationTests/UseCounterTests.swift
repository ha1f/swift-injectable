import Presentation
import Testing

@Suite("UseCounter", .serialized)
@MainActor
struct UseCounterTests {
    @Test("初期値が0")
    func initialValue() {
        let counter = UseCounter()
        #expect(counter.count == 0)
    }

    @Test("初期値を指定できる")
    func customInitialValue() {
        let counter = UseCounter(count: 10)
        #expect(counter.count == 10)
    }

    @Test("incrementでカウントが1増える")
    func increment() {
        let counter = UseCounter()
        counter.increment()
        #expect(counter.count == 1)
    }

    @Test("decrementでカウントが1減る")
    func decrement() {
        let counter = UseCounter()
        counter.decrement()
        #expect(counter.count == -1)
    }

    @Test("resetでカウントが0に戻る")
    func reset() {
        let counter = UseCounter(count: 5)
        counter.reset()
        #expect(counter.count == 0)
    }

    @Test("複数操作の組み合わせ")
    func multipleOperations() {
        let counter = UseCounter()
        counter.increment()
        counter.increment()
        counter.decrement()
        #expect(counter.count == 1)
    }
}
