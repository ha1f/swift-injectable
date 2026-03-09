import Foundation
import Mockable

/// TodoのCRUD操作を提供するユースケース
@Mockable
@MainActor
public protocol TodoUseCaseProtocol: Sendable {
    /// 現在のTodoリスト（Repository から透過的に公開）
    var todos: [Todo] { get }
    func fetchAll() async throws
    func add(title: String) async throws
    func toggleCompletion(_ todo: Todo) async throws
    func delete(id: UUID) async throws
}
