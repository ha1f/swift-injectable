import Domain

/// コンソールにログ出力する実装
public struct ConsoleLogger: LoggerProtocol {
    public init() {}

    public func log(_ message: String) {
        print("[LOG] \(message)")
    }
}
