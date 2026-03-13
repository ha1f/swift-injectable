@testable import Domain
import SwiftInjectable
import Testing

@Suite("@Injected(default:) テスト")
@MainActor
struct InjectedDefaultTests {

    @Test("デフォルト値が未登録時に使われる")
    func fallbackToDefault() async {
        await withTestInjection(configure: { _ in }) {
            @Injected(default: StubLogger()) var logger: any LoggerProtocol
            logger.log("test")
        }
    }

    @Test("登録済みの場合はデフォルト値より登録値が優先される")
    func registeredOverridesDefault() async {
        let mockLogger = LoggerProtocolMock()
        mockLogger.logHandler = { _ in }

        await withTestInjection(configure: { store in
            store.register(mockLogger, for: (any LoggerProtocol).self)
        }) {
            @Injected(default: StubLogger()) var logger: any LoggerProtocol
            logger.log("test")
            #expect(mockLogger.logCallCount == 1)
        }
    }
}

private struct StubLogger: LoggerProtocol, Sendable {
    func log(_ message: String) {}
}
