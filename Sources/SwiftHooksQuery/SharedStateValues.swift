import Observation
import SwiftInjectable
import SwiftUI

// MARK: - SharedStateBox

/// 共有状態の値を保持する @Observable ボックス
/// キーごとに1つのインスタンスが作られ、SwiftUI のビュー更新を駆動する
@Observable
@MainActor
public final class SharedStateBox<Value: Sendable>: @unchecked Sendable {
    public var value: Value

    init(_ value: Value) {
        self.value = value
    }
}

// MARK: - SharedStateValues

/// 共有状態の値を格納するコンテナ
/// SwiftUI の `EnvironmentValues` と同じパターンで使用する
///
/// キーごとに `SharedStateBox` を1つ保持し、@Observable による
/// 粒度の高い変更追跡を実現する
@MainActor
public final class SharedStateValues: @unchecked Sendable {
    private var boxes: [ObjectIdentifier: Any] = [:]

    public nonisolated init() {}

    /// キーに対応する SharedStateBox を取得する（なければ defaultValue で作成）
    public func box<K: SharedStateKey>(for key: K.Type) -> SharedStateBox<K.Value> {
        let id = ObjectIdentifier(key)
        if let existing = boxes[id] as? SharedStateBox<K.Value> {
            return existing
        }
        let newBox = SharedStateBox(K.defaultValue)
        boxes[id] = newBox
        return newBox
    }

    public subscript<K: SharedStateKey>(key: K.Type) -> K.Value {
        get { box(for: key).value }
        set { box(for: key).value = newValue }
    }
}

// MARK: - SwiftUI Environment 統合

@MainActor
private struct SharedStateValuesEnvironmentKey: EnvironmentKey {
    nonisolated static let defaultValue = SharedStateValues()
}

extension EnvironmentValues {
    /// 共有状態のコンテナ
    public var sharedStateValues: SharedStateValues {
        get { self[SharedStateValuesEnvironmentKey.self] }
        set { self[SharedStateValuesEnvironmentKey.self] = newValue }
    }
}

// MARK: - InjectionStore 統合

extension InjectionStore {
    /// 共有状態のコンテナ
    /// `withTestInjection` 内で共有状態をセットアップするために使用する
    ///
    /// ```swift
    /// await withTestInjection(configure: { store in
    ///     store.sharedState.counter = 42
    /// }) {
    ///     let hook = UseCounter()
    ///     #expect(hook.counter.value == 42)
    /// }
    /// ```
    public var sharedState: SharedStateValues {
        mutating get {
            if let existing = resolve(SharedStateValues.self) {
                return existing
            }
            let new = SharedStateValues()
            register(new, for: SharedStateValues.self)
            return new
        }
        set {
            register(newValue, for: SharedStateValues.self)
        }
    }
}
