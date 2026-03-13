import Domain
import SwiftHooks
import SwiftUI

/// Todoフィルターの状態を管理するhook
@Hook
@MainActor
public struct UseTodoFilter {
    @HookState public var currentFilter: TodoFilter = .all

    /// フィルターに基づいてTodoリストを絞り込む
    public func apply(to todos: [Todo]) -> [Todo] {
        switch currentFilter {
        case .all:
            return todos
        case .active:
            return todos.filter { !$0.isCompleted }
        case .completed:
            return todos.filter { $0.isCompleted }
        }
    }
}
