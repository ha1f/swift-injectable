import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import SwiftInjectableMacrosPlugin

final class InjectableMacroTests: XCTestCase {
    private let testMacros: [String: Macro.Type] = [
        "Injectable": InjectableMacro.self,
    ]

    // MARK: - 基本的な展開

    /// @Inject 付きプロパティ2つ → container init + 直接注入 init が生成されること
    func testBasicExpansionWithTwoInjectProperties() {
        assertMacroExpansion(
            """
            @Injectable
            final class MyViewModel {
                @Inject var apiClient: any APIClientProtocol
                @Inject var logger: any LoggerProtocol
            }
            """,
            expandedSource: """
            final class MyViewModel {
                @Inject var apiClient: any APIClientProtocol
                @Inject var logger: any LoggerProtocol

                init(container: Container) {
                    self._apiClient = Inject(container.resolve((any APIClientProtocol).self))
                    self._logger = Inject(container.resolve((any LoggerProtocol).self))
                }

                init(apiClient: any APIClientProtocol, logger: any LoggerProtocol) {
                    self._apiClient = Inject(apiClient)
                    self._logger = Inject(logger)
                }
            }

            extension MyViewModel: Injectable {
            }
            """,
            macros: testMacros
        )
    }

    // MARK: - @Inject なしのプロパティはスキップ

    /// @Inject が付いていない通常のプロパティは init に含まれないこと
    func testNonInjectPropertiesAreSkipped() {
        assertMacroExpansion(
            """
            @Injectable
            final class MyService {
                @Inject var apiClient: any APIClientProtocol
                var count: Int = 0
            }
            """,
            expandedSource: """
            final class MyService {
                @Inject var apiClient: any APIClientProtocol
                var count: Int = 0

                init(container: Container) {
                    self._apiClient = Inject(container.resolve((any APIClientProtocol).self))
                }

                init(apiClient: any APIClientProtocol) {
                    self._apiClient = Inject(apiClient)
                }
            }

            extension MyService: Injectable {
            }
            """,
            macros: testMacros
        )
    }

    // MARK: - @Inject プロパティが0個

    /// @Inject プロパティが0個なら container init のみ生成（直接注入 init は不要）
    func testZeroInjectProperties() {
        assertMacroExpansion(
            """
            @Injectable
            final class EmptyService {
                var count: Int = 0
            }
            """,
            expandedSource: """
            final class EmptyService {
                var count: Int = 0

                init(container: Container) {

                }
            }

            extension EmptyService: Injectable {
            }
            """,
            macros: testMacros
        )
    }

    // MARK: - struct に適用したらエラー

    /// class 以外に適用するとエラーになること
    func testStructProducesError() {
        assertMacroExpansion(
            """
            @Injectable
            struct MyStruct {
                @Inject var apiClient: any APIClientProtocol
            }
            """,
            expandedSource: """
            struct MyStruct {
                @Inject var apiClient: any APIClientProtocol
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Injectable はクラスにのみ適用できます",
                    line: 1,
                    column: 1
                ),
            ],
            macros: testMacros
        )
    }

    // MARK: - 追加引数プロパティ

    /// @Inject + 追加引数 → 両方の init に追加引数が含まれること
    func testExtraArgumentProperties() {
        assertMacroExpansion(
            """
            @Injectable
            final class MyService {
                @Inject var apiClient: any APIClientProtocol
                let userId: Int
                let label: String
                var count: Int = 0
            }
            """,
            expandedSource: """
            final class MyService {
                @Inject var apiClient: any APIClientProtocol
                let userId: Int
                let label: String
                var count: Int = 0

                init(container: Container, userId: Int, label: String) {
                    self._apiClient = Inject(container.resolve((any APIClientProtocol).self))
                    self.userId = userId
                    self.label = label
                }

                init(apiClient: any APIClientProtocol, userId: Int, label: String) {
                    self._apiClient = Inject(apiClient)
                    self.userId = userId
                    self.label = label
                }
            }
            """,
            macros: testMacros
        )
    }

    // MARK: - let に @Inject を付けた場合はスキップ

    /// let に @Inject を付けてもスキップされること（var のみ対象）
    func testLetInjectPropertySkipped() {
        assertMacroExpansion(
            """
            @Injectable
            final class MyService {
                @Inject let apiClient: any APIClientProtocol
            }
            """,
            expandedSource: """
            final class MyService {
                @Inject let apiClient: any APIClientProtocol

                init(container: Container) {

                }
            }

            extension MyService: Injectable {
            }
            """,
            macros: testMacros
        )
    }

    // MARK: - existential 型 (any Protocol)

    /// any SomeProtocol 型が正しく展開されること（両方の init で）
    func testExistentialType() {
        assertMacroExpansion(
            """
            @Injectable
            final class Foo {
                @Inject var bar: any BarProtocol
            }
            """,
            expandedSource: """
            final class Foo {
                @Inject var bar: any BarProtocol

                init(container: Container) {
                    self._bar = Inject(container.resolve((any BarProtocol).self))
                }

                init(bar: any BarProtocol) {
                    self._bar = Inject(bar)
                }
            }

            extension Foo: Injectable {
            }
            """,
            macros: testMacros
        )
    }
}
