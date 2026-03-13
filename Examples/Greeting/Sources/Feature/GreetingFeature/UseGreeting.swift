import Domain
import SwiftHooks
import SwiftInjectable
import SwiftUI

/// 名前から挨拶文を生成するhook（@Hook + @Injected の例）
@Hook
@MainActor
public struct UseGreeting {
    @Injected var greetingProvider: any GreetingProviderProtocol
    @HookState public var name: String = ""

    public var greetingText: String {
        name.isEmpty ? "" : greetingProvider.greeting(for: name)
    }
}
