import Domain

public struct ConsoleLogger: LoggerProtocol {
    public init() {}

    public func log(_ message: String) {
        print("[LOG] \(message)")
    }
}
