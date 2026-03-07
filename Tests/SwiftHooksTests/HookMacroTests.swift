import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import SwiftHooksMacrosPlugin

final class HookMacroTests: XCTestCase {
    private let testMacros: [String: Macro.Type] = [
        "Hook": HookMacro.self,
        "_HookAccessor": HookAccessorMacro.self,
    ]

    // MARK: - 基本展開

    func testBasicExpansion() {
        assertMacroExpansion(
            """
            @Hook
            struct UseCounter {
                var count: Int = 0
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

    // MARK: - stored var なし（Storage 不要）

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

    // MARK: - 複数の stored var

    func testMultipleStoredVars() {
        assertMacroExpansion(
            """
            @Hook
            struct UseFetchUser {
                var user: User? = nil
                var isLoading: Bool = false
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

    // MARK: - @Injected は除外

    func testInjectedPropertyIsIgnored() {
        assertMacroExpansion(
            """
            @Hook
            struct UseFetchUser {
                @Injected var userUseCase: any UserUseCaseProtocol
                var isLoading: Bool = false
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
                var count: Int = 0
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

    // MARK: - デフォルト値なしの stored var

    func testStoredVarWithoutDefault() {
        assertMacroExpansion(
            """
            @Hook
            struct UseValue {
                var value: String
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
                var count: Int = 0
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
                final class Storage {
                    var count: Int
                    init(
                        count: Int
                    ) {
                            self.count = count
                    }
                }

                @SwiftUI.State private var hookStorage: Storage

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
}
