@_exported import SwiftInjectable

@attached(member, names: named(init), arbitrary)
@attached(extension, conformances: Injectable)
public macro Injectable() = #externalMacro(
    module: "SwiftInjectableMacrosPlugin",
    type: "InjectableMacro"
)
