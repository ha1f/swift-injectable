import Dependencies
import Domain
import GreetingFeature
import Testing

@Suite("UseGreeting")
@MainActor
struct UseGreetingTests {

    @Test("名前が空のとき、greetingTextは空文字")
    func emptyName() {
        withDependencies {
            $0.greetingProvider = StubGreetingProvider()
        } operation: {
            let hook = UseGreeting()
            #expect(hook.greetingText == "")
        }
    }

    @Test("名前を設定するとgreetingTextが生成される")
    func withName() {
        withDependencies {
            $0.greetingProvider = StubGreetingProvider()
        } operation: {
            let hook = UseGreeting()
            hook.name = "Alice"
            #expect(hook.greetingText == "Hi, Alice!")
        }
    }

    @Test("注入されたproviderが使われる")
    func usesInjectedProvider() {
        withDependencies {
            $0.greetingProvider = StubGreetingProvider { "こんにちは、\($0)さん！" }
        } operation: {
            let hook = UseGreeting()
            hook.name = "太郎"
            #expect(hook.greetingText == "こんにちは、太郎さん！")
        }
    }
}

private struct StubGreetingProvider: GreetingProviderProtocol {
    var handler: @Sendable (String) -> String = { "Hi, \($0)!" }

    func greeting(for name: String) -> String {
        handler(name)
    }
}
