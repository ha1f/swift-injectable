import SwiftUI
import SwiftInjectable

// TODO: 最小ターゲットを iOS 18 / macOS 15 に上げたら @Entry に置き換える
// extension EnvironmentValues {
//     @Entry var container = Container()
// }
private struct ContainerKey: EnvironmentKey {
    static let defaultValue = Container()
}

public extension EnvironmentValues {
    var container: Container {
        get { self[ContainerKey.self] }
        set { self[ContainerKey.self] = newValue }
    }
}
