import Domain
import SwiftHooks
import SwiftInjectable
import SwiftUI

@Hook
@MainActor
public struct UseLogger {
    @Injected var logger: any LoggerProtocol

    public func log(_ message: String) {
        logger.log(message)
    }
}
