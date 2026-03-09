import Foundation
import Mockable

/// Todoの永続化を担うリポジトリ
@Mockable
@MainActor
public protocol TodoRepositoryProtocol: Sendable {
    /// 現在のTodoリスト（@Observable で変更通知される想定）
    var todos: [Todo] { get }
    func fetchAll() async throws
    func add(_ todo: Todo) async throws
    func update(_ todo: Todo) async throws
    func delete(id: UUID) async throws
}
