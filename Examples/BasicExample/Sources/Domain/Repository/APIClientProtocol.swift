import Foundation
import Mockable

@Mockable
public protocol APIClientProtocol: Sendable {
    func fetchUser(id: Int) async throws -> User
}
