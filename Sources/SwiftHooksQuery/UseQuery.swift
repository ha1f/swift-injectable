import SwiftInjectable
import SwiftUI

/// クエリキャッシュにアクセスするための DynamicProperty
/// Apollo Client の useQuery に倣った設計
///
/// ```swift
/// @Hook
/// struct UseTodosQuery {
///     @Injected var repository: any TodoRepositoryProtocol
///     let query = UseQuery(\.todos, cachePolicy: .cacheFirst)
///
///     func fetch() async {
///         await query.fetch {
///             try await repository.fetchAll()
///         }
///     }
/// }
/// ```
@MainActor
public struct UseQuery<Value: Sendable>: DynamicProperty {
    @Injected(default: QueryCache()) var cacheRepository: QueryCache
    private let keyPath: KeyPath<QueryCache, QueryEntry<Value>>
    private let cachePolicy: QueryCachePolicy

    public init(
        _ keyPath: KeyPath<QueryCache, QueryEntry<Value>>,
        cachePolicy: QueryCachePolicy = .cacheFirst
    ) {
        self.keyPath = keyPath
        self.cachePolicy = cachePolicy
    }

    private var entry: QueryEntry<Value> {
        cacheRepository[keyPath: keyPath]
    }

    /// 取得済みデータ
    public var data: Value? { entry.data }

    /// 読み込み中かどうか
    public var isLoading: Bool { entry.isLoading }

    /// 最後に発生したエラー
    public var error: (any Error)? { entry.error }

    /// データを取得してキャッシュに書き込む
    /// `cachePolicy` に従い、不要な fetch をスキップする
    public func fetch(_ fetcher: @Sendable () async throws -> Value) async {
        switch cachePolicy {
        case .cacheOnly:
            return
        case .cacheFirst:
            if entry.data != nil { return }
            await performFetch(fetcher)
        case .networkOnly:
            await performFetch(fetcher)
        case .cacheAndNetwork:
            await performFetch(fetcher)
        }
    }

    /// キャッシュを無効化してデータをクリアする
    public func invalidate() {
        entry.data = nil
        entry.error = nil
    }

    private func performFetch(_ fetcher: @Sendable () async throws -> Value) async {
        entry.startLoading()
        do {
            let result = try await fetcher()
            entry.succeed(result)
        } catch {
            entry.fail(error)
        }
    }
}
