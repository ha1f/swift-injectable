@_exported import SwiftInjectable
@_exported import SwiftInjectableSwiftUI

/// 依存としてマークする。@Injectable マクロが読み取り Dependencies struct に含める。
@attached(peer)
public macro Dependency() = #externalMacro(
    module: "SwiftInjectableMacrosPlugin",
    type: "DependencyMacro"
)

/// Dependencies struct、init、Injectable 準拠を自動生成する。
@attached(member, names: named(Dependencies), named(init), arbitrary)
@attached(extension, conformances: Injectable, AutoInjectable)
public macro Injectable() = #externalMacro(
    module: "SwiftInjectableMacrosPlugin",
    type: "InjectableMacro"
)
