import Domain
import Foundation
import SwiftHooks
import SwiftHooksQuery
import SwiftInjectable
import SwiftUI

/// Todoリストの状態管理を提供するhook
/// UseQueryでキャッシュを管理し、Repository操作のエラーハンドリングを行う
@Hook
@MainActor
public struct UseTodoList {
    @Injected var repository: any TodoRepositoryProtocol
    @Injected var logger: any LoggerProtocol

    public let query = UseQuery(\.todos)

    @HookState public var error: (any Error)? = nil

    /// キャッシュ上の最新のTodoリスト
    public var todos: [Todo] {
        query.data ?? []
    }

    /// ローディング中かどうか
    public var isLoading: Bool {
        query.isLoading
    }

    /// Todo一覧を取得する
    public func fetchAll() async {
        await query.fetch {
            try await repository.fetchAll()
        }
        if let queryError = query.error {
            error = queryError
        } else {
            error = nil
        }
    }

    /// Todoの完了状態をトグルする
    public func toggleCompletion(_ todo: Todo) async {
        do {
            var updated = todo
            updated.isCompleted.toggle()
            try await repository.update(updated)
            logger.log("Todoの完了状態を変更: \(todo.title) → \(updated.isCompleted)")
            // キャッシュを更新
            query.invalidate()
            await query.fetch { try await repository.fetchAll() }
            error = nil
        } catch {
            self.error = error
        }
    }

    /// Todoを削除する
    public func delete(id: UUID) async {
        do {
            try await repository.delete(id: id)
            logger.log("Todoを削除: \(id)")
            query.invalidate()
            await query.fetch { try await repository.fetchAll() }
            error = nil
        } catch {
            self.error = error
        }
    }

    /// Todoを追加する
    public func add(title: String) async {
        do {
            let todo = Todo(title: title)
            try await repository.add(todo)
            logger.log("Todoを追加: \(title)")
            query.invalidate()
            await query.fetch { try await repository.fetchAll() }
            error = nil
        } catch {
            self.error = error
        }
    }

    /// エラーをクリアする
    public func clearError() {
        error = nil
    }
}
