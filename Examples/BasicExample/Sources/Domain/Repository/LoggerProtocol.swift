import Foundation
import Mockable

@Mockable
public protocol LoggerProtocol: Sendable {
    func log(_ message: String)
}
