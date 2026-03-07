import SwiftUI
import SwiftInjectableMacros

struct UseLogger: DynamicProperty {
    @Inject var deps: AppContainer

    func log(_ message: String) {
        deps.logger.log(message)
    }
}
