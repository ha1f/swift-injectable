import Foundation
import Mockable

/// TodoのCRUD操作を提供するユースケース
@Mockable
public protocol TodoUseCaseProtocol: Sendable {
    func fetchAll() async throws -> [Todo]
    func add(title: String) async throws -> Todo
    func toggleCompletion(_ todo: Todo) async throws -> Todo
    func delete(id: UUID) async throws
}
