import Dependencies
import Domain
import SwiftHooks
import SwiftUI

/// 名前から挨拶文を生成するhook（@Hook + @Dependency の例）
@Hook
@MainActor
public struct UseGreeting {
    @Dependency(\.greetingProvider) var greetingProvider
    @HookState public var name: String = ""

    public var greetingText: String {
        name.isEmpty ? "" : greetingProvider.greeting(for: name)
    }
}
