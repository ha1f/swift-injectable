import SwiftUI
import SwiftInjectableMacros

struct UseLogger: DynamicProperty {
    @Deps var deps: AppContainer

    func log(_ message: String) {
        deps.logger.log(message)
    }
}
