import Testing
@testable import SwiftInjectable

// MARK: - テスト用ヘルパー型

private protocol ServiceProtocol: Sendable {
    var id: String { get }
}

private final class ServiceImpl: ServiceProtocol, @unchecked Sendable {
    let id: String

    init(id: String = "default") {
        self.id = id
    }
}

/// factory 呼び出し回数を記録するカウンター
private final class CallCounter: @unchecked Sendable {
    private(set) var count = 0

    func increment() {
        count += 1
    }
}

// MARK: - 連鎖解決用の型

private final class ServiceC: Injectable, Sendable {
    let value = "C"

    init(container: Container) {}
}

private final class ServiceB: Injectable, @unchecked Sendable {
    let c: ServiceC

    init(container: Container) {
        self.c = container.resolve(ServiceC.self)
    }
}

private final class ServiceA: Injectable, @unchecked Sendable {
    let b: ServiceB

    init(container: Container) {
        self.b = container.resolve(ServiceB.self)
    }
}

// MARK: - Injectable 自動解決用

private final class AutoResolvable: Injectable, Sendable {
    let name = "auto"

    init(container: Container) {}
}

// MARK: - テスト

@Suite("Container テスト")
struct ContainerTests {

    // 1. singleton の登録と解決: 同じインスタンスが返ること（protocol経由）
    @Test("singleton 登録は同じインスタンスを返す")
    func singleRegistrationReturnsSameInstance() {
        let container = Container {
            $0.singleton(ServiceProtocol.self) { _ in ServiceImpl(id: "singleton") }
        }
        let first = container.resolve(ServiceProtocol.self)
        let second = container.resolve(ServiceProtocol.self)
        #expect(first.id == "singleton")
        #expect(first.id == second.id)
        // 参照同一性を確認
        #expect(first as AnyObject === second as AnyObject)
    }

    // 2. factory の登録と解決: 毎回異なるインスタンスが返ること
    @Test("factory 登録は毎回異なるインスタンスを返す")
    func factoryRegistrationReturnsDifferentInstances() {
        let container = Container {
            $0.factory(ServiceProtocol.self) { _ in ServiceImpl() }
        }
        let first = container.resolve(ServiceProtocol.self)
        let second = container.resolve(ServiceProtocol.self)
        #expect(first as AnyObject !== second as AnyObject)
    }

    // 3. Injectable 型の自動解決: 登録なしで Injectable 準拠型が解決されること
    @Test("Injectable 準拠型は登録なしで解決できる")
    func injectableTypeAutoResolved() {
        let container = Container()
        let instance = container.resolve(AutoResolvable.self)
        #expect(instance.name == "auto")
    }

    // 4. 連鎖解決 (A->B->C): 依存チェーンが正しく解決されること
    @Test("連鎖依存 A->B->C が正しく解決される")
    func chainedDependencyResolution() {
        let container = Container()
        let a = container.resolve(ServiceA.self)
        #expect(a.b.c.value == "C")
    }

    // 5. 未登録の型を resolve したら fatalError
    // fatalError はプロセスを終了させるため、Swift Testing では直接テストできない。スキップ。

    // 6. @Inject property wrapper: init で値をセットし wrappedValue で取得できること
    @Test("@Inject property wrapper で値を取得できる")
    func injectPropertyWrapper() {
        let inject = Inject<String>("hello")
        #expect(inject.wrappedValue == "hello")
    }

    // 7. single が本当に1回しか生成しないこと: factory のカウンタで検証
    @Test("singleton は factory を1回だけ呼ぶ")
    func singleCallsFactoryOnlyOnce() {
        let counter = CallCounter()
        let container = Container {
            $0.singleton(ServiceProtocol.self) { _ in
                counter.increment()
                return ServiceImpl()
            }
        }
        _ = container.resolve(ServiceProtocol.self)
        _ = container.resolve(ServiceProtocol.self)
        _ = container.resolve(ServiceProtocol.self)
        #expect(counter.count == 1)
    }
}
