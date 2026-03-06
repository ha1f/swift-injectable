public protocol Injectable {
    associatedtype Dependencies
}

/// 追加パラメータなしで Dependencies から自動生成できる Injectable
public protocol AutoInjectable: Injectable {
    init(deps: Dependencies)
}
