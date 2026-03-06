import Foundation

public final class Container: @unchecked Sendable {
    private let lock = NSRecursiveLock()
    private var registrations: [ObjectIdentifier: Registration] = [:]
    private var singletonCache: [ObjectIdentifier: any Sendable] = [:]
    private var resolvingStack: [ObjectIdentifier] = []

    public init(_ configure: (Container) -> Void = { _ in }) {
        configure(self)
    }

    // MARK: - 登録

    /// シングルトン登録（遅延生成、1回だけ）
    @discardableResult
    public func singleton<T: Sendable>(_ type: T.Type, factory: @escaping @Sendable (Container) -> T) -> Container {
        lock.lock()
        defer { lock.unlock() }
        registrations[ObjectIdentifier(type)] = Registration(scope: .singleton, factory: factory)
        return self
    }

    /// 毎回新規生成登録
    @discardableResult
    public func factory<T: Sendable>(_ type: T.Type, factory: @escaping @Sendable (Container) -> T) -> Container {
        lock.lock()
        defer { lock.unlock() }
        registrations[ObjectIdentifier(type)] = Registration(scope: .factory, factory: factory)
        return self
    }

    // MARK: - 解決

    public func resolve<T>(_ type: T.Type = T.self) -> T {
        lock.lock()
        defer { lock.unlock() }

        let key = ObjectIdentifier(type)

        // 循環依存検出
        if resolvingStack.contains(key) {
            let chain = resolvingStack.map { id in
                // スタック内の型名は取れないので、循環が発生した型名を含める
                "\(id)"
            }
            fatalError("Circular dependency detected while resolving \(type). Resolution stack: \(chain)")
        }

        resolvingStack.append(key)
        defer { resolvingStack.removeLast() }

        // 1. 登録済みならそこから解決
        if let registration = registrations[key] {
            switch registration.scope {
            case .singleton:
                if let cached = singletonCache[key] as? T {
                    return cached
                }
                let instance = registration.factory(self)
                guard let typed = instance as? T else {
                    fatalError("Registration for \(type) returned incompatible type \(Swift.type(of: instance)).")
                }
                singletonCache[key] = instance
                return typed
            case .factory:
                let instance = registration.factory(self)
                guard let typed = instance as? T else {
                    fatalError("Registration for \(type) returned incompatible type \(Swift.type(of: instance)).")
                }
                return typed
            }
        }

        // 2. 解決不能
        fatalError("No registration found for \(type).")
    }
}
