import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct SwiftInjectableMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        InjectableMacro.self,
        ProvideMacro.self,
    ]
}
