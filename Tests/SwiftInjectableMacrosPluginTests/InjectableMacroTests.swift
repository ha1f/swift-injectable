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
                var userUseCase: any UserUseCaseProtocol = UserUseCase()
                var logger: any LoggerProtocol = ConsoleLogger()
            }
            """,
            expandedSource: """
            struct AppDependencies {
                var userUseCase: any UserUseCaseProtocol = UserUseCase()
                var logger: any LoggerProtocol = ConsoleLogger()

                func body(content: Content) -> some View {
                    content
                        .environment(\\.userUseCase, userUseCase)
                        .environment(\\.logger, logger)
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
                var logger: any LoggerProtocol = ConsoleLogger()
            }
            """,
            expandedSource: """
            class BadDeps {
                var logger: any LoggerProtocol = ConsoleLogger()
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
