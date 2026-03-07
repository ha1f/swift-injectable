import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import SwiftInjectableMacrosPlugin

final class InjectableMacroTests: XCTestCase {
    private let testMacros: [String: Macro.Type] = [
        "Injectable": InjectableMacro.self,
        "Provide": ProvideMacro.self,
    ]

    func testBasicExpansion() {
        assertMacroExpansion(
            """
            @Injectable
            class AppDependencies {
                @Provide(as: (any LoggerProtocol).self)
                lazy var logger = ConsoleLogger()
                @Provide(as: (any APIClientProtocol).self)
                lazy var apiClient = LiveAPIClient()
            }
            """,
            expandedSource: """
            class AppDependencies {
                lazy var logger = ConsoleLogger()
                lazy var apiClient = LiveAPIClient()

                func registerAll(in store: inout InjectionStore) {
                    store.register(logger, for: (any LoggerProtocol).self)
                    store.register(apiClient, for: (any APIClientProtocol).self)
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

                func registerAll(in store: inout InjectionStore) {
                }
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
                @Provide(as: (any LoggerProtocol).self)
                lazy var logger = ConsoleLogger()
            }
            """,
            expandedSource: """
            struct BadContainer {
                lazy var logger = ConsoleLogger()
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Injectable can only be applied to classes",
                    line: 1,
                    column: 1
                ),
            ],
            macros: testMacros
        )
    }

    func testPropertyWithoutProvideIsIgnored() {
        assertMacroExpansion(
            """
            @Injectable
            class Container {
                var logger: any LoggerProtocol = ConsoleLogger()
            }
            """,
            expandedSource: """
            class Container {
                var logger: any LoggerProtocol = ConsoleLogger()

                func registerAll(in store: inout InjectionStore) {
                }
            }

            extension Container: InjectableContainer {
            }
            """,
            macros: testMacros
        )
    }

    func testSingleProvideProperty() {
        assertMacroExpansion(
            """
            @Injectable
            class Container {
                @Provide(as: (any LoggerProtocol).self)
                lazy var logger = ConsoleLogger()
            }
            """,
            expandedSource: """
            class Container {
                lazy var logger = ConsoleLogger()

                func registerAll(in store: inout InjectionStore) {
                    store.register(logger, for: (any LoggerProtocol).self)
                }
            }

            extension Container: InjectableContainer {
            }
            """,
            macros: testMacros
        )
    }
}
