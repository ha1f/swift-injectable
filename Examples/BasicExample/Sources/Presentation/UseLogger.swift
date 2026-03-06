import SwiftUI

struct UseLogger: DynamicProperty {
    @Environment(\.logger) private var logger

    func log(_ message: String) {
        logger.log(message)
    }
}
