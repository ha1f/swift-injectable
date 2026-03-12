import Foundation
import SwiftInjectable
import SwiftHooksQuery
import Testing

// MARK: - テスト用キー定義

private enum NumbersQueryKey: QueryKey {
    typealias Value = [Int]
}

private enum StringQueryKey: QueryKey {
    typealias Value = String
}

extension QueryCache {
    var numbers: QueryEntry<[Int]> {
        entry(for: NumbersQueryKey.self)
    }

    var text: QueryEntry<String> {
        entry(for: StringQueryKey.self)
    }
}

// MARK: - QueryCache テスト

@Suite("QueryCache テスト")
@MainActor
struct QueryCacheTests {

    @Test("初期状態: data は nil")
    func initialState() {
        let cache = QueryCache()
        let entry = cache.numbers
        #expect(entry.data == nil)
        #expect(entry.isLoading == false)
        #expect(entry.error == nil)
    }

    @Test("同じキーのentryは同一インスタンスを返す")
    func sameEntryInstance() {
        let cache = QueryCache()
        let entry1 = cache.entry(for: NumbersQueryKey.self)
        let entry2 = cache.entry(for: NumbersQueryKey.self)
        #expect(entry1 === entry2)
    }

    @Test("異なるキーのentryは別インスタンスを返す")
    func differentEntryInstances() {
        let cache = QueryCache()
        let numbersEntry = cache.entry(for: NumbersQueryKey.self)
        let stringEntry = cache.entry(for: StringQueryKey.self)
        #expect(numbersEntry !== stringEntry)
    }

    @Test("data を直接設定して取得できる")
    func directDataAccess() {
        let cache = QueryCache()
        cache.numbers.data = [1, 2, 3]
        #expect(cache.numbers.data == [1, 2, 3])
    }
}

// MARK: - UseQuery cachePolicy テスト

@Suite("UseQuery cachePolicy テスト")
@MainActor
struct UseQueryCachePolicyTests {

    @Test("cacheFirst: データがなければ fetch する")
    func cacheFirstFetchesWhenEmpty() async {
        await withTestInjection(configure: { store in _ = store.queryCache }) {
            let query = UseQuery(\.numbers, cachePolicy: .cacheFirst)
            await query.fetch { [1, 2, 3] }
            #expect(query.data == [1, 2, 3])
            #expect(query.isLoading == false)
            #expect(query.error == nil)
        }
    }

    @Test("cacheFirst: データがあれば fetch しない")
    func cacheFirstSkipsWhenCached() async {
        await withTestInjection(configure: { store in
            store.queryCache.numbers.data = [1, 2, 3]
        }) {
            let query = UseQuery(\.numbers, cachePolicy: .cacheFirst)
            await query.fetch { [4, 5, 6] }
            #expect(query.data == [1, 2, 3])
        }
    }

    @Test("networkOnly: キャッシュがあっても常に fetch する")
    func networkOnlyAlwaysFetches() async {
        await withTestInjection(configure: { store in
            store.queryCache.numbers.data = [1, 2, 3]
        }) {
            let query = UseQuery(\.numbers, cachePolicy: .networkOnly)
            await query.fetch { [4, 5, 6] }
            #expect(query.data == [4, 5, 6])
        }
    }

    @Test("cacheOnly: fetch しない")
    func cacheOnlyNeverFetches() async {
        await withTestInjection(configure: { store in
            store.queryCache.numbers.data = [1, 2, 3]
        }) {
            let query = UseQuery(\.numbers, cachePolicy: .cacheOnly)
            await query.fetch { [4, 5, 6] }
            #expect(query.data == [1, 2, 3])
        }
    }

    @Test("cacheAndNetwork: キャッシュがあっても fetch して更新する")
    func cacheAndNetworkFetchesAndUpdates() async {
        await withTestInjection(configure: { store in
            store.queryCache.numbers.data = [1, 2, 3]
        }) {
            let query = UseQuery(\.numbers, cachePolicy: .cacheAndNetwork)
            await query.fetch { [4, 5, 6] }
            #expect(query.data == [4, 5, 6])
        }
    }

    @Test("fetch 失敗時に error が設定される")
    func fetchFailure() async {
        await withTestInjection(configure: { store in _ = store.queryCache }) {
            let query = UseQuery(\.numbers, cachePolicy: .networkOnly)
            await query.fetch { throw URLError(.notConnectedToInternet) }
            #expect(query.data == nil)
            #expect(query.error != nil)
            #expect(query.isLoading == false)
        }
    }

    @Test("fetch 成功後の失敗: data は残る")
    func dataPreservedAfterFailure() async {
        await withTestInjection(configure: { store in _ = store.queryCache }) {
            let query = UseQuery(\.numbers, cachePolicy: .networkOnly)
            await query.fetch { [1, 2, 3] }
            #expect(query.data == [1, 2, 3])

            await query.fetch { throw URLError(.badURL) }
            #expect(query.data == [1, 2, 3])
            #expect(query.error != nil)
        }
    }

    @Test("invalidate: キャッシュがクリアされる")
    func invalidate() async {
        await withTestInjection(configure: { store in
            store.queryCache.numbers.data = [1, 2, 3]
        }) {
            let query = UseQuery(\.numbers)
            #expect(query.data == [1, 2, 3])
            query.invalidate()
            #expect(query.data == nil)
            #expect(query.error == nil)
        }
    }
}

// MARK: - キャッシュ共有テスト

@Suite("QueryCache 共有テスト")
@MainActor
struct QueryCacheSharingTests {

    @Test("同じキーの UseQuery は同じキャッシュを共有する")
    func sharedCache() async {
        await withTestInjection(configure: { store in _ = store.queryCache }) {
            let query1 = UseQuery(\.numbers)
            let query2 = UseQuery(\.numbers)

            await query1.fetch { [1, 2, 3] }

            #expect(query2.data == [1, 2, 3])
        }
    }

    @Test("異なるキーの UseQuery は独立している")
    func independentKeys() async {
        await withTestInjection(configure: { store in _ = store.queryCache }) {
            let numbersQuery = UseQuery(\.numbers)
            let textQuery = UseQuery(\.text)

            await numbersQuery.fetch { [1, 2, 3] }
            await textQuery.fetch { "hello" }

            #expect(numbersQuery.data == [1, 2, 3])
            #expect(textQuery.data == "hello")
        }
    }
}
