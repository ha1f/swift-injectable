import SwiftInjectable
import SwiftUI

/// 共有状態にアクセスするための DynamicProperty
/// SwiftUI の `@Environment` と同じパターンで使用する
///
/// ```swift
/// @Hook
/// struct UseTodoList {
///     let todos = UseSharedState(\.todos)
///
///     func fetchAll() async throws {
///         todos.value = try await repository.fetchAll()
///     }
/// }
/// ```
@MainActor
public struct UseSharedState<Value: Sendable>: DynamicProperty {
    @Environment(\.sharedStateValues) private var _environmentValues
    private let keyPath: ReferenceWritableKeyPath<SharedStateValues, Value>

    public init(_ keyPath: ReferenceWritableKeyPath<SharedStateValues, Value>) {
        self.keyPath = keyPath
    }

    private var resolvedValues: SharedStateValues {
        // テスト用オーバーライドを優先（InjectionOverride + TaskLocal）
        if let override = InjectionOverride.current,
           let values = override.resolve(SharedStateValues.self) {
            return values
        }
        return _environmentValues
    }

    /// 共有状態の現在の値
    public var value: Value {
        get { resolvedValues[keyPath: keyPath] }
        nonmutating set { resolvedValues[keyPath: keyPath] = newValue }
    }

    /// SwiftUI Binding を返す
    public var binding: Binding<Value> {
        Binding(
            get: { resolvedValues[keyPath: keyPath] },
            set: { resolvedValues[keyPath: keyPath] = $0 }
        )
    }
}
