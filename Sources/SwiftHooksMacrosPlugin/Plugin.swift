import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct SwiftHooksMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        HookMacro.self,
        HookAccessorMacro.self,
        HookStateMacro.self,
    ]
}
