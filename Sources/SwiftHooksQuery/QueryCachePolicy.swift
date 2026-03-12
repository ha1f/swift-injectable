/// クエリのキャッシュポリシー
/// Apollo Client の fetchPolicy に倣った設計
public enum QueryCachePolicy: Sendable {
    /// キャッシュにデータがあればそれを返し、なければ fetch する（デフォルト）
    case cacheFirst
    /// 常に fetch する。結果はキャッシュに書き込む
    case networkOnly
    /// キャッシュのみ参照する。fetch しない
    case cacheOnly
    /// キャッシュを先に返し、裏で fetch して更新する（stale-while-revalidate）
    case cacheAndNetwork
}
