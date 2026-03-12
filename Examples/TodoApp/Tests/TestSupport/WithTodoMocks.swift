@testable import Domain
import Foundation
import SwiftInjectable

/// Todoアプリのテスト用共通ヘルパー
/// Repository + Logger のモックを自動セットアップし、テストコードを簡潔にする
@MainActor
public func withTodoMocks(
    todos: [Todo] = [],
    configure: ((TodoRepositoryProtocolMock) -> Void)? = nil,
    body: (TodoRepositoryProtocolMock) async throws -> Void
) async rethrows {
    let repo = TodoRepositoryProtocolMock()
    repo._todos = todos
    let logger = LoggerProtocolMock()
    logger.logHandler = { _ in }
    configure?(repo)

    try await withTestInjection(configure: { store in
        store.register(repo, for: (any TodoRepositoryProtocol).self)
        store.register(logger, for: (any LoggerProtocol).self)
    }) {
        try await body(repo)
    }
}
