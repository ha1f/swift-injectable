import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct SwiftInjectableMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        DependencyMacro.self,
        InjectableMacro.self,
    ]
}
