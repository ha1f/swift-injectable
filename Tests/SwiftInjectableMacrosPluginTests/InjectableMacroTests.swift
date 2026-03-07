import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import SwiftInjectableMacrosPlugin

final class DependenciesMacroTests: XCTestCase {
    private let testMacros: [String: Macro.Type] = [
        "Dependencies": DependenciesMacro.self,
    ]

    func testBasicExpansion() {
        assertMacroExpansion(
            """
            @Dependencies
            struct AppDependencies {
                var logger: any LoggerProtocol { _logger ?? ConsoleLogger() }
                var userUseCase: any UserUseCaseProtocol { _userUseCase ?? UserUseCase() }
            }
            """,
            expandedSource: """
            struct AppDependencies {
                var logger: any LoggerProtocol { _logger ?? ConsoleLogger() }
                var userUseCase: any UserUseCaseProtocol { _userUseCase ?? UserUseCase() }

                var _logger: (any LoggerProtocol)?

                var _userUseCase: (any UserUseCaseProtocol)?

                init(_ logger: (any LoggerProtocol)? = nil, _ userUseCase: (any UserUseCaseProtocol)? = nil) {
                    self._logger = logger
                    self._userUseCase = userUseCase
                }

                func body(content: Content) -> some View {
                    content
                        .transformEnvironment(\\.dependenciesStore) { store in
                            store.register(self)
                        }
                }
            }

            extension AppDependencies: ViewModifier {
            }
            """,
            macros: testMacros
        )
    }

    func testEmptyStruct() {
        assertMacroExpansion(
            """
            @Dependencies
            struct EmptyDeps {
            }
            """,
            expandedSource: """
            struct EmptyDeps {
            }

            extension EmptyDeps: ViewModifier {
            }
            """,
            macros: testMacros
        )
    }

    func testClassProducesError() {
        assertMacroExpansion(
            """
            @Dependencies
            class BadDeps {
                var logger: any LoggerProtocol { ConsoleLogger() }
            }
            """,
            expandedSource: """
            class BadDeps {
                var logger: any LoggerProtocol { ConsoleLogger() }
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Dependencies は struct にのみ適用できます",
                    line: 1,
                    column: 1
                ),
            ],
            macros: testMacros
        )
    }
}
