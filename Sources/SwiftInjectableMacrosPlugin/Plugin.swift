import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct SwiftInjectableMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ProviderMacro.self,
        ProvideMacro.self,
    ]
}
