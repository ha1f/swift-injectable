import Domain
import SwiftHooks
import SwiftInjectable
import SwiftUI
import TodoListFeature

/// Todoの統計情報を提供するhook（UseTodoListとの合成例）
@Hook
@MainActor
public struct UseTodoStats {
    /// UseTodoListを合成して統計を導出する
    public let todoList = UseTodoList()

    public init() {}

    /// 現在のTodoリストから統計情報を計算する
    public var stats: TodoStats {
        let total = todoList.todos.count
        let completed = todoList.todos.filter(\.isCompleted).count
        let active = total - completed
        return TodoStats(total: total, active: active, completed: completed)
    }

    /// 完了率（0.0〜1.0）
    public var completionRate: Double {
        guard stats.total > 0 else { return 0 }
        return Double(stats.completed) / Double(stats.total)
    }
}
