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
            class AppContainer {
                func createLogger() -> any LoggerProtocol { ConsoleLogger() }
                func createUserUseCase() -> any UserUseCaseProtocol { UserUseCase() }
            }
            """,
            expandedSource: """
            class AppContainer {
                func createLogger() -> any LoggerProtocol { ConsoleLogger() }
                func createUserUseCase() -> any UserUseCaseProtocol { UserUseCase() }

                private var _logger: (any LoggerProtocol)?

                var logger: any LoggerProtocol {
                    if let v = _logger {
                        return v
                    }
                    let v = createLogger()
                    _logger = v
                    return v
                }

                private var _userUseCase: (any UserUseCaseProtocol)?

                var userUseCase: any UserUseCaseProtocol {
                    if let v = _userUseCase {
                        return v
                    }
                    let v = createUserUseCase()
                    _userUseCase = v
                    return v
                }

                init(logger: (any LoggerProtocol)? = nil, userUseCase: (any UserUseCaseProtocol)? = nil) {
                    self._logger = logger
                    self._userUseCase = userUseCase
                }
            }

            protocol AppContainerProtocol {
                var logger: any LoggerProtocol {
                    get
                }
                var userUseCase: any UserUseCaseProtocol {
                    get
                }
            }
            """,
            macros: testMacros
        )
    }

    func testEmptyClass() {
        assertMacroExpansion(
            """
            @Dependencies
            class EmptyContainer {
            }
            """,
            expandedSource: """
            class EmptyContainer {
            }
            """,
            macros: testMacros
        )
    }

    func testStructProducesError() {
        assertMacroExpansion(
            """
            @Dependencies
            struct BadContainer {
                func createLogger() -> any LoggerProtocol { ConsoleLogger() }
            }
            """,
            expandedSource: """
            struct BadContainer {
                func createLogger() -> any LoggerProtocol { ConsoleLogger() }
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Dependencies は class にのみ適用できます",
                    line: 1,
                    column: 1
                ),
            ],
            macros: testMacros
        )
    }
}
