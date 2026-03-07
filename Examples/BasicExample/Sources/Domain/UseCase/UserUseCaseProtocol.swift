import Foundation
import Mockable

@Mockable
public protocol UserUseCaseProtocol: Sendable {
    func fetch(userId: Int) async throws -> User
}
