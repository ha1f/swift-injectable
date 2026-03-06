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

// MARK: - テスト

@Suite("Container テスト")
struct ContainerTests {

    @Test("singleton 登録は同じインスタンスを返す")
    func singleRegistrationReturnsSameInstance() {
        let container = Container {
            $0.singleton(ServiceProtocol.self) { _ in ServiceImpl(id: "singleton") }
        }
        let first = container.resolve(ServiceProtocol.self)
        let second = container.resolve(ServiceProtocol.self)
        #expect(first.id == "singleton")
        #expect(first.id == second.id)
        #expect(first as AnyObject === second as AnyObject)
    }

    @Test("factory 登録は毎回異なるインスタンスを返す")
    func factoryRegistrationReturnsDifferentInstances() {
        let container = Container {
            $0.factory(ServiceProtocol.self) { _ in ServiceImpl() }
        }
        let first = container.resolve(ServiceProtocol.self)
        let second = container.resolve(ServiceProtocol.self)
        #expect(first as AnyObject !== second as AnyObject)
    }

    @Test("連鎖依存が正しく解決される")
    func chainedDependencyResolution() {
        let container = Container {
            $0.singleton(ServiceProtocol.self) { _ in ServiceImpl(id: "C") }
        }
        let resolved = container.resolve(ServiceProtocol.self)
        #expect(resolved.id == "C")
    }

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
