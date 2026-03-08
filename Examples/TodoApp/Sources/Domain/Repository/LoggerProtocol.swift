import Foundation
import Mockable

/// ログ出力のインターフェース
@Mockable
public protocol LoggerProtocol: Sendable {
    func log(_ message: String)
}
