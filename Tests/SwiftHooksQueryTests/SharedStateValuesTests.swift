import SwiftInjectable
import SwiftHooksQuery
import Testing

// MARK: - テスト用キー定義

private enum CounterKey: SharedStateKey {
    static let defaultValue: Int = 0
}

private enum NameKey: SharedStateKey {
    static let defaultValue: String = ""
}

private enum ItemsKey: SharedStateKey {
    static let defaultValue: [String] = []
}

extension SharedStateValues {
    var counter: Int {
        get { self[CounterKey.self] }
        set { self[CounterKey.self] = newValue }
    }

    var name: String {
        get { self[NameKey.self] }
        set { self[NameKey.self] = newValue }
    }

    var items: [String] {
        get { self[ItemsKey.self] }
        set { self[ItemsKey.self] = newValue }
    }
}

// MARK: - SharedStateValues テスト

@Suite("SharedStateValues テスト")
@MainActor
struct SharedStateValuesTests {

    @Test("未設定のキーはdefaultValueを返す")
    func defaultValue() {
        let values = SharedStateValues()
        #expect(values[CounterKey.self] == 0)
        #expect(values[NameKey.self] == "")
        #expect(values[ItemsKey.self] == [])
    }

    @Test("値の読み書きができる")
    func readWrite() {
        let values = SharedStateValues()
        values[CounterKey.self] = 42
        #expect(values[CounterKey.self] == 42)
    }

    @Test("KeyPath経由の読み書きができる")
    func keyPathAccess() {
        let values = SharedStateValues()
        values.counter = 10
        values.name = "test"
        #expect(values.counter == 10)
        #expect(values.name == "test")
    }

    @Test("異なるキーは独立している")
    func independentKeys() {
        let values = SharedStateValues()
        values[CounterKey.self] = 99
        values[NameKey.self] = "hello"
        #expect(values[CounterKey.self] == 99)
        #expect(values[NameKey.self] == "hello")
    }

    @Test("同じキーのboxは同一インスタンスを返す")
    func sameBoxInstance() {
        let values = SharedStateValues()
        let box1 = values.box(for: CounterKey.self)
        let box2 = values.box(for: CounterKey.self)
        #expect(box1 === box2)
    }

    @Test("異なるキーのboxは別インスタンスを返す")
    func differentBoxInstances() {
        let values = SharedStateValues()
        let counterBox = values.box(for: CounterKey.self)
        let nameBox = values.box(for: NameKey.self)
        #expect(counterBox !== nameBox)
    }

    @Test("box経由の変更がsubscript経由で反映される")
    func boxMutationReflected() {
        let values = SharedStateValues()
        let box = values.box(for: CounterKey.self)
        box.value = 100
        #expect(values[CounterKey.self] == 100)
    }
}

// MARK: - InjectionStore 統合テスト

@Suite("InjectionStore.sharedState テスト")
@MainActor
struct InjectionStoreSharedStateTests {

    @Test("withTestInjection 内で共有状態をセットアップできる")
    func setupInTestInjection() async {
        await withTestInjection(configure: { store in
            store.sharedState.counter = 42
            store.sharedState.name = "test"
        }) {
            let override = InjectionOverride.current
            let values = override?.resolve(SharedStateValues.self)
            #expect(values?.counter == 42)
            #expect(values?.name == "test")
        }
    }

    @Test("withTestInjection 外ではオーバーライドがない")
    func noOverrideOutside() {
        #expect(InjectionOverride.current == nil)
    }

    @Test("ネストした withTestInjection は内側が優先される")
    func nestedOverride() async {
        await withTestInjection(configure: { store in
            store.sharedState.counter = 1
        }) {
            let values1 = InjectionOverride.current?.resolve(SharedStateValues.self)
            #expect(values1?.counter == 1)

            await withTestInjection(configure: { store in
                store.sharedState.counter = 2
            }) {
                let values2 = InjectionOverride.current?.resolve(SharedStateValues.self)
                #expect(values2?.counter == 2)
            }

            // 外側に戻る
            let values3 = InjectionOverride.current?.resolve(SharedStateValues.self)
            #expect(values3?.counter == 1)
        }
    }

    @Test("異なるオーバーライドが互いに干渉しない")
    func isolation() async {
        await withTestInjection(configure: { store in
            store.sharedState.counter = 100
            store.sharedState.name = "first"
        }) {
            let values1 = InjectionOverride.current?.resolve(SharedStateValues.self)
            #expect(values1?.counter == 100)
            #expect(values1?.name == "first")
        }

        // 前のオーバーライドの影響が残らない
        await withTestInjection(configure: { store in
            store.sharedState.counter = 200
        }) {
            let values2 = InjectionOverride.current?.resolve(SharedStateValues.self)
            #expect(values2?.counter == 200)
            #expect(values2?.name == "")
        }
    }
}
