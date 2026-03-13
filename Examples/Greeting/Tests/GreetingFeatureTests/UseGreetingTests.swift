@testable import Domain
import GreetingFeature
import SwiftInjectable
import Testing

@Suite("UseGreeting")
@MainActor
struct UseGreetingTests {

    private func withMockGreeting(
        handler: @escaping @Sendable (String) -> String = { "Hello, \($0)!" },
        body: (GreetingProviderProtocolMock) async throws -> Void
    ) async rethrows {
        let mock = GreetingProviderProtocolMock()
        mock.greetingHandler = handler

        try await withTestInjection(configure: { store in
            store.register(mock, for: (any GreetingProviderProtocol).self)
        }) {
            try await body(mock)
        }
    }

    @Test("名前が空のとき、greetingTextは空文字")
    func emptyName() async {
        await withMockGreeting { _ in
            let hook = UseGreeting()
            #expect(hook.greetingText == "")
        }
    }

    @Test("名前を設定するとgreetingTextが生成される")
    func withName() async {
        await withMockGreeting { _ in
            let hook = UseGreeting()
            hook.name = "Alice"
            #expect(hook.greetingText == "Hello, Alice!")
        }
    }

    @Test("注入されたproviderが使われる")
    func usesInjectedProvider() async {
        await withMockGreeting(handler: { "こんにちは、\($0)さん！" }) { mock in
            let hook = UseGreeting()
            hook.name = "太郎"
            #expect(hook.greetingText == "こんにちは、太郎さん！")
            #expect(mock.greetingCallCount == 1)
        }
    }

    @Test("名前を変更するとgreetingTextも変わる")
    func nameChange() async {
        await withMockGreeting { _ in
            let hook = UseGreeting()
            hook.name = "Alice"
            #expect(hook.greetingText == "Hello, Alice!")
            hook.name = "Bob"
            #expect(hook.greetingText == "Hello, Bob!")
        }
    }
}
