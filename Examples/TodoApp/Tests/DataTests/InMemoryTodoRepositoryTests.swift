import Data
import Domain
import Foundation
import Testing

@Suite("InMemoryTodoRepository テスト")
@MainActor
struct InMemoryTodoRepositoryTests {

    @Test("初期状態: 空のリストを返す")
    func fetchAllEmpty() async throws {
        let repo = InMemoryTodoRepository()
        #expect(repo.todos.isEmpty)
    }

    @Test("初期値付き: 指定したTodoが含まれる")
    func fetchAllWithInitial() async throws {
        let initial = [Todo(title: "初期Todo")]
        let repo = InMemoryTodoRepository(initialTodos: initial)

        #expect(repo.todos.count == 1)
        #expect(repo.todos[0].title == "初期Todo")
    }

    @Test("add: Todoを追加するとtodosに反映される")
    func addAndFetch() async throws {
        let repo = InMemoryTodoRepository()
        let todo = Todo(title: "追加されたTodo")

        try await repo.add(todo)

        #expect(repo.todos.count == 1)
        #expect(repo.todos[0] == todo)
    }

    @Test("update: 既存のTodoを更新する")
    func update() async throws {
        let todo = Todo(title: "元のタイトル")
        let repo = InMemoryTodoRepository(initialTodos: [todo])

        var updated = todo
        updated.title = "更新されたタイトル"
        updated.isCompleted = true
        try await repo.update(updated)

        #expect(repo.todos[0].title == "更新されたタイトル")
        #expect(repo.todos[0].isCompleted == true)
    }

    @Test("update: 存在しないIDでエラーになる")
    func updateNotFound() async {
        let repo = InMemoryTodoRepository()
        let todo = Todo(title: "存在しない")

        do {
            try await repo.update(todo)
            Issue.record("エラーが発生するはず")
        } catch {
            #expect(error as? TodoRepositoryError == .notFound)
        }
    }

    @Test("delete: 指定IDのTodoを削除する")
    func delete() async throws {
        let todo = Todo(title: "削除対象")
        let repo = InMemoryTodoRepository(initialTodos: [todo])

        try await repo.delete(id: todo.id)
        #expect(repo.todos.isEmpty)
    }

    @Test("delete: 存在しないIDでエラーになる")
    func deleteNotFound() async {
        let repo = InMemoryTodoRepository()

        do {
            try await repo.delete(id: UUID())
            Issue.record("エラーが発生するはず")
        } catch {
            #expect(error as? TodoRepositoryError == .notFound)
        }
    }

    @Test("複数のTodoを管理できる")
    func multipleItems() async throws {
        let repo = InMemoryTodoRepository()
        let todo1 = Todo(title: "Todo1")
        let todo2 = Todo(title: "Todo2")
        let todo3 = Todo(title: "Todo3")

        try await repo.add(todo1)
        try await repo.add(todo2)
        try await repo.add(todo3)

        try await repo.delete(id: todo2.id)

        #expect(repo.todos.count == 2)
        #expect(repo.todos.map(\.title) == ["Todo1", "Todo3"])
    }
}
