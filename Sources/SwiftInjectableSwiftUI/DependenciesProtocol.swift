@_exported import SwiftUI
import SwiftInjectable

public protocol DependenciesProtocol: DynamicProperty {
    associatedtype Target: Injectable
    init()
    func resolve() -> Target.Dependencies
}
