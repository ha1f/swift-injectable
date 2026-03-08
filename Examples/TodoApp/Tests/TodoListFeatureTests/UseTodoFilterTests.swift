import Domain
import Testing
import TodoListFeature

@Suite("UseTodoFilter テスト")
@MainActor
struct UseTodoFilterTests {
    private let todos = [
        Todo(title: "未完了1", isCompleted: false),
        Todo(title: "完了1", isCompleted: true),
        Todo(title: "未完了2", isCompleted: false),
        Todo(title: "完了2", isCompleted: true),
    ]

    @Test("初期状態: allフィルターが選択されている")
    func initialState() {
        let filter = UseTodoFilter()
        #expect(filter.currentFilter == .all)
    }

    @Test("allフィルター: すべてのTodoを返す")
    func filterAll() {
        let filter = UseTodoFilter()
        filter.currentFilter = .all
        let result = filter.apply(to: todos)
        #expect(result.count == 4)
    }

    @Test("activeフィルター: 未完了のTodoのみ返す")
    func filterActive() {
        let filter = UseTodoFilter()
        filter.currentFilter = .active
        let result = filter.apply(to: todos)

        #expect(result.count == 2)
        #expect(result.allSatisfy { !$0.isCompleted })
    }

    @Test("completedフィルター: 完了済みのTodoのみ返す")
    func filterCompleted() {
        let filter = UseTodoFilter()
        filter.currentFilter = .completed
        let result = filter.apply(to: todos)

        #expect(result.count == 2)
        #expect(result.allSatisfy { $0.isCompleted })
    }

    @Test("空のリストに対してフィルターを適用しても空を返す")
    func filterEmpty() {
        let filter = UseTodoFilter()
        filter.currentFilter = .active
        let result = filter.apply(to: [])
        #expect(result.isEmpty)
    }
}
