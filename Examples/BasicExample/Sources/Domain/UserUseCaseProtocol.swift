import Foundation
import Mockable

@Mockable
protocol UserUseCaseProtocol: Sendable {
    func execute(userId: Int) async throws -> User
}
