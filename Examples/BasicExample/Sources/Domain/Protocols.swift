import Foundation
import Mockable

// MARK: - モデル

struct User: Sendable, Identifiable {
    let id: Int
    let name: String
}

// MARK: - Repository

@Mockable
protocol APIClientProtocol: Sendable {
    func fetchUser(id: Int) async throws -> User
}

@Mockable
protocol LoggerProtocol: Sendable {
    func log(_ message: String)
}

// MARK: - UseCase

@Mockable
protocol UserUseCaseProtocol: Sendable {
    func execute(userId: Int) async throws -> User
}
