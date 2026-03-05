import Foundation
import Mockable

@Mockable
protocol APIClientProtocol: Sendable {
    func fetchUser(id: Int) async throws -> User
}

@Mockable
protocol LoggerProtocol: Sendable {
    func log(_ message: String)
}

struct User: Sendable, Identifiable {
    let id: Int
    let name: String
}
