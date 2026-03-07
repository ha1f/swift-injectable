import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import SwiftInjectableMacrosPlugin

final class InjectableMacroTests: XCTestCase {
    private let testMacros: [String: Macro.Type] = [
        "Injectable": InjectableMacro.self,
    ]

    func testBasicExpansion() {
        assertMacroExpansion(
            """
            @Injectable
            class AppDependencies {
                lazy var logger: any LoggerProtocol = ConsoleLogger()
                lazy var apiClient: any APIClientProtocol = LiveAPIClient()
            }
            """,
            expandedSource: """
            class AppDependencies {
                lazy var logger: any LoggerProtocol = ConsoleLogger()
                lazy var apiClient: any APIClientProtocol = LiveAPIClient()

                func registerAll(in store: inout InjectionStore) {
                    store.register(logger, as: (any LoggerProtocol).self)
                    store.register(apiClient, as: (any APIClientProtocol).self)
                }

                init(logger: (any LoggerProtocol)? = nil, apiClient: (any APIClientProtocol)? = nil) {
                    if let logger {
                        self.logger = logger
                    }
                    if let apiClient {
                        self.apiClient = apiClient
                    }
                }
            }

            extension AppDependencies: InjectableContainer {
            }
            """,
            macros: testMacros
        )
    }

    func testEmptyClass() {
        assertMacroExpansion(
            """
            @Injectable
            class EmptyContainer {
            }
            """,
            expandedSource: """
            class EmptyContainer {
            }

            extension EmptyContainer: InjectableContainer {
            }
            """,
            macros: testMacros
        )
    }

    func testStructProducesError() {
        assertMacroExpansion(
            """
            @Injectable
            struct BadContainer {
                lazy var logger: any LoggerProtocol = ConsoleLogger()
            }
            """,
            expandedSource: """
            struct BadContainer {
                lazy var logger: any LoggerProtocol = ConsoleLogger()
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Injectable は class にのみ適用できます",
                    line: 1,
                    column: 1
                ),
            ],
            macros: testMacros
        )
    }
}
