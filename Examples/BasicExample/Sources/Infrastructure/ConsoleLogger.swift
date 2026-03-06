import Foundation

struct ConsoleLogger: LoggerProtocol {
    func log(_ message: String) {
        print("[LOG] \(message)")
    }
}
