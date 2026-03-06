import Foundation

struct LiveAPIClient: APIClientProtocol {
    func fetchUser(id: Int) async throws -> User {
        // 実際にはネットワークリクエスト
        try await Task.sleep(for: .milliseconds(500))
        return User(id: id, name: "User \(id)")
    }
}

struct ConsoleLogger: LoggerProtocol {
    func log(_ message: String) {
        print("[LOG] \(message)")
    }
}
