import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import SwiftInjectableMacrosPlugin

final class ProviderMacroTests: XCTestCase {
    private let testMacros: [String: Macro.Type] = [
        "Provider": ProviderMacro.self,
        "Provide": ProvideMacro.self,
    ]

    func testBasicExpansion() {
        assertMacroExpansion(
            """
            @Provider
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

            extension AppDependencies: DependencyProvider {
            }
            """,
            macros: testMacros
        )
    }

    func testEmptyClass() {
        assertMacroExpansion(
            """
            @Provider
            class EmptyContainer {
            }
            """,
            expandedSource: """
            class EmptyContainer {

                func registerAll(in store: inout InjectionStore) {
                }
            }

            extension EmptyContainer: DependencyProvider {
            }
            """,
            macros: testMacros
        )
    }

    func testStructProducesError() {
        assertMacroExpansion(
            """
            @Provider
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
                    message: "@Provider can only be applied to classes",
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
            @Provider
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

            extension Container: DependencyProvider {
            }
            """,
            macros: testMacros
        )
    }

    func testSingleProvideProperty() {
        assertMacroExpansion(
            """
            @Provider
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

            extension Container: DependencyProvider {
            }
            """,
            macros: testMacros
        )
    }
}
