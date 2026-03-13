import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import SwiftHooksMacrosPlugin

final class HookMacroTests: XCTestCase {
    private let testMacros: [String: Macro.Type] = [
        "Hook": HookMacro.self,
        "HookState": HookStateMacro.self,
        "_HookAccessor": HookAccessorMacro.self,
    ]

    // MARK: - 基本展開

    func testBasicExpansion() {
        assertMacroExpansion(
            """
            @Hook
            struct UseCounter {
                @HookState var count: Int = 0
                func increment() { count += 1 }
            }
            """,
            expandedSource: """
            struct UseCounter {
                var count: Int {
                    @storageRestrictions(initializes: _hook_backing_count)
                    init(initialValue) {
                        _hook_backing_count = initialValue
                    }
                    get {
                        hookStorage.count
                    }
                    nonmutating set {
                        hookStorage.count = newValue
                    }
                }

                private var _hook_backing_count: Int
                func increment() { count += 1 }

                @Observable
                final class Storage {
                    var count: Int
                    init(
                        count: Int
                    ) {
                            self.count = count
                    }
                }

                @SwiftUI.State private var hookStorage: Storage

                var binding: SwiftUI.Binding<Storage> {
                    $hookStorage
                }

                init(
                        count: Int = 0
                ) {
                    self.count = count
                    _hookStorage = SwiftUI.State(initialValue: Storage(
                            count: count
                    ))
                }
            }

            extension UseCounter: DynamicProperty {
            }
            """,
            macros: testMacros
        )
    }

    // MARK: - @HookState なし（Storage 不要）

    func testNoStoredVars() {
        assertMacroExpansion(
            """
            @Hook
            struct UseDisplay {
                let counter = UseCounter()
                var displayText: String { "Count: \\(counter.count)" }
            }
            """,
            expandedSource: """
            struct UseDisplay {
                let counter = UseCounter()
                var displayText: String { "Count: \\(counter.count)" }
            }

            extension UseDisplay: DynamicProperty {
            }
            """,
            macros: testMacros
        )
    }

    // MARK: - 複数の @HookState var

    func testMultipleStoredVars() {
        assertMacroExpansion(
            """
            @Hook
            struct UseFetchUser {
                @HookState var user: User? = nil
                @HookState var isLoading: Bool = false
            }
            """,
            expandedSource: """
            struct UseFetchUser {
                var user: User? {
                    @storageRestrictions(initializes: _hook_backing_user)
                    init(initialValue) {
                        _hook_backing_user = initialValue
                    }
                    get {
                        hookStorage.user
                    }
                    nonmutating set {
                        hookStorage.user = newValue
                    }
                }

                private var _hook_backing_user: User?
                var isLoading: Bool {
                    @storageRestrictions(initializes: _hook_backing_isLoading)
                    init(initialValue) {
                        _hook_backing_isLoading = initialValue
                    }
                    get {
                        hookStorage.isLoading
                    }
                    nonmutating set {
                        hookStorage.isLoading = newValue
                    }
                }

                private var _hook_backing_isLoading: Bool

                @Observable
                final class Storage {
                    var user: User?
                    var isLoading: Bool
                    init(
                        user: User?,
                        isLoading: Bool
                    ) {
                            self.user = user
                            self.isLoading = isLoading
                    }
                }

                @SwiftUI.State private var hookStorage: Storage

                var binding: SwiftUI.Binding<Storage> {
                    $hookStorage
                }

                init(
                        user: User? = nil,
                        isLoading: Bool = false
                ) {
                    self.user = user
                    self.isLoading = isLoading
                    _hookStorage = SwiftUI.State(initialValue: Storage(
                            user: user,
                            isLoading: isLoading
                    ))
                }
            }

            extension UseFetchUser: DynamicProperty {
            }
            """,
            macros: testMacros
        )
    }

    // MARK: - @Injected は @HookState なしなので除外

    func testInjectedPropertyIsIgnored() {
        assertMacroExpansion(
            """
            @Hook
            struct UseFetchUser {
                @Injected var userUseCase: any UserUseCaseProtocol
                @HookState var isLoading: Bool = false
            }
            """,
            expandedSource: """
            struct UseFetchUser {
                @Injected var userUseCase: any UserUseCaseProtocol
                var isLoading: Bool {
                    @storageRestrictions(initializes: _hook_backing_isLoading)
                    init(initialValue) {
                        _hook_backing_isLoading = initialValue
                    }
                    get {
                        hookStorage.isLoading
                    }
                    nonmutating set {
                        hookStorage.isLoading = newValue
                    }
                }

                private var _hook_backing_isLoading: Bool

                @Observable
                final class Storage {
                    var isLoading: Bool
                    init(
                        isLoading: Bool
                    ) {
                            self.isLoading = isLoading
                    }
                }

                @SwiftUI.State private var hookStorage: Storage

                var binding: SwiftUI.Binding<Storage> {
                    $hookStorage
                }

                init(
                        isLoading: Bool = false
                ) {
                    self.isLoading = isLoading
                    _hookStorage = SwiftUI.State(initialValue: Storage(
                            isLoading: isLoading
                    ))
                }
            }

            extension UseFetchUser: DynamicProperty {
            }
            """,
            macros: testMacros
        )
    }

    // MARK: - class にはエラー

    func testClassProducesError() {
        assertMacroExpansion(
            """
            @Hook
            class BadHook {
                @HookState var count: Int = 0
            }
            """,
            expandedSource: """
            class BadHook {
                var count: Int = 0
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Hook can only be applied to structs",
                    line: 1,
                    column: 1
                ),
            ],
            macros: testMacros
        )
    }

    // MARK: - デフォルト値なしの @HookState var

    func testStoredVarWithoutDefault() {
        assertMacroExpansion(
            """
            @Hook
            struct UseValue {
                @HookState var value: String
            }
            """,
            expandedSource: """
            struct UseValue {
                var value: String {
                    @storageRestrictions(initializes: _hook_backing_value)
                    init(initialValue) {
                        _hook_backing_value = initialValue
                    }
                    get {
                        hookStorage.value
                    }
                    nonmutating set {
                        hookStorage.value = newValue
                    }
                }

                private var _hook_backing_value: String

                @Observable
                final class Storage {
                    var value: String
                    init(
                        value: String
                    ) {
                            self.value = value
                    }
                }

                @SwiftUI.State private var hookStorage: Storage

                var binding: SwiftUI.Binding<Storage> {
                    $hookStorage
                }

                init(
                        value: String
                ) {
                    self.value = value
                    _hookStorage = SwiftUI.State(initialValue: Storage(
                            value: value
                    ))
                }
            }

            extension UseValue: DynamicProperty {
            }
            """,
            macros: testMacros
        )
    }

    // MARK: - public struct

    func testPublicStruct() {
        assertMacroExpansion(
            """
            @Hook
            public struct UseCounter {
                @HookState var count: Int = 0
            }
            """,
            expandedSource: """
            public struct UseCounter {
                var count: Int {
                    @storageRestrictions(initializes: _hook_backing_count)
                    init(initialValue) {
                        _hook_backing_count = initialValue
                    }
                    get {
                        hookStorage.count
                    }
                    nonmutating set {
                        hookStorage.count = newValue
                    }
                }

                private var _hook_backing_count: Int

                @Observable
                public final class Storage {
                    public var count: Int
                    init(
                        count: Int
                    ) {
                            self.count = count
                    }
                }

                @SwiftUI.State private var hookStorage: Storage

                public var binding: SwiftUI.Binding<Storage> {
                    $hookStorage
                }

                public init(
                        count: Int = 0
                ) {
                    self.count = count
                    _hookStorage = SwiftUI.State(initialValue: Storage(
                            count: count
                    ))
                }
            }

            extension UseCounter: DynamicProperty {
            }
            """,
            macros: testMacros
        )
    }

    // MARK: - ジェネリック struct

    func testGenericStruct() {
        assertMacroExpansion(
            """
            @Hook
            struct UseValue<T> {
                @HookState var value: T
            }
            """,
            expandedSource: """
            struct UseValue<T> {
                var value: T {
                    @storageRestrictions(initializes: _hook_backing_value)
                    init(initialValue) {
                        _hook_backing_value = initialValue
                    }
                    get {
                        hookStorage.value
                    }
                    nonmutating set {
                        hookStorage.value = newValue
                    }
                }

                private var _hook_backing_value: T

                @Observable
                final class Storage {
                    var value: T
                    init(
                        value: T
                    ) {
                            self.value = value
                    }
                }

                @SwiftUI.State private var hookStorage: Storage

                var binding: SwiftUI.Binding<Storage> {
                    $hookStorage
                }

                init(
                        value: T
                ) {
                    self.value = value
                    _hookStorage = SwiftUI.State(initialValue: Storage(
                            value: value
                    ))
                }
            }

            extension UseValue: DynamicProperty {
            }
            """,
            macros: testMacros
        )
    }

    // MARK: - @HookState に型注釈なしはエラー

    func testMissingTypeAnnotationProducesError() {
        assertMacroExpansion(
            """
            @Hook
            struct UseCounter {
                @HookState var count = 0
            }
            """,
            expandedSource: """
            struct UseCounter {
                var count = 0
            }

            extension UseCounter: DynamicProperty {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Hook requires type annotation on stored property 'count'. Write 'var count: Type = ...' instead.",
                    line: 3,
                    column: 5
                ),
            ],
            macros: testMacros
        )
    }

    // MARK: - @State は警告

    func testStatePropertyProducesWarning() {
        assertMacroExpansion(
            """
            @Hook
            struct UseCounter {
                @State var count: Int = 0
            }
            """,
            expandedSource: """
            struct UseCounter {
                @State var count: Int = 0
            }

            extension UseCounter: DynamicProperty {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@State should not be used inside @Hook. Use @HookState on 'count' instead.",
                    line: 3,
                    column: 5,
                    severity: .warning
                ),
            ],
            macros: testMacros
        )
    }

    // MARK: - @HookState なしの var は無視される

    func testPlainVarIsIgnored() {
        assertMacroExpansion(
            """
            @Hook
            struct UseGreeting {
                @Dependency var provider: any GreetingProvider
                var config: Config = .default
                @HookState var name: String = ""
            }
            """,
            expandedSource: """
            struct UseGreeting {
                @Dependency var provider: any GreetingProvider
                var config: Config = .default
                var name: String {
                    @storageRestrictions(initializes: _hook_backing_name)
                    init(initialValue) {
                        _hook_backing_name = initialValue
                    }
                    get {
                        hookStorage.name
                    }
                    nonmutating set {
                        hookStorage.name = newValue
                    }
                }

                private var _hook_backing_name: String

                @Observable
                final class Storage {
                    var name: String
                    init(
                        name: String
                    ) {
                            self.name = name
                    }
                }

                @SwiftUI.State private var hookStorage: Storage

                var binding: SwiftUI.Binding<Storage> {
                    $hookStorage
                }

                init(
                        name: String = ""
                ) {
                    self.name = name
                    _hookStorage = SwiftUI.State(initialValue: Storage(
                            name: name
                    ))
                }
            }

            extension UseGreeting: DynamicProperty {
            }
            """,
            macros: testMacros
        )
    }
}
