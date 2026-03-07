import Domain
import SwiftInjectable
import SwiftUI

@MainActor
public struct UseLogger: DynamicProperty {
    @Inject var logger: any LoggerProtocol

    public init() {}

    public func log(_ message: String) {
        logger.log(message)
    }
}
