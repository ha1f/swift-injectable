import SwiftUI
import Testing
import SwiftInjectable
@testable import SwiftInjectableSwiftUI

@Suite("EnvironmentValues.container テスト")
struct EnvironmentValuesContainerTests {

    @Test("デフォルト値は空の Container")
    func defaultValueIsEmptyContainer() {
        let env = EnvironmentValues()
        // デフォルトの Container が存在すること（クラッシュしないこと）
        let container = env.container
        #expect(container is Container)
    }

    @Test("set/get で Container を保持できる")
    func setAndGetContainer() {
        var env = EnvironmentValues()
        let container = Container {
            $0.singleton(String.self) { _ in "hello" }
        }
        env.container = container
        let resolved = env.container.resolve(String.self)
        #expect(resolved == "hello")
    }
}
