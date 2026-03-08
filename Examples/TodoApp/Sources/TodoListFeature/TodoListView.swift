import Domain
import TodoDetailFeature
import SwiftUI

/// Todoリスト画面
public struct TodoListView: View {
    var todoList = UseTodoList()
    var filter = UseTodoFilter()

    public init() {}

    public var body: some View {
        VStack {
            // フィルターセグメント
            Picker("フィルター", selection: Binding(
                get: { filter.currentFilter },
                set: { filter.currentFilter = $0 }
            )) {
                Text("すべて").tag(TodoFilter.all)
                Text("未完了").tag(TodoFilter.active)
                Text("完了").tag(TodoFilter.completed)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            if todoList.isLoading {
                ProgressView()
                    .frame(maxHeight: .infinity)
            } else {
                let filteredTodos = filter.apply(to: todoList.todos)
                if filteredTodos.isEmpty {
                    ContentUnavailableView(
                        "Todoがありません",
                        systemImage: "checklist"
                    )
                } else {
                    List {
                        ForEach(filteredTodos) { todo in
                            NavigationLink {
                                TodoDetailView(todo: todo)
                            } label: {
                                TodoRowView(todo: todo) {
                                    Task {
                                        await todoList.toggleCompletion(todo)
                                    }
                                }
                            }
                        }
                        .onDelete { indexSet in
                            let filtered = filter.apply(to: todoList.todos)
                            for index in indexSet {
                                let todo = filtered[index]
                                Task {
                                    await todoList.delete(id: todo.id)
                                }
                            }
                        }
                    }
                }
            }
        }
        .alert(
            "エラー",
            isPresented: Binding(
                get: { todoList.error != nil },
                set: { if !$0 { todoList.clearError() } }
            )
        ) {
            Button("リトライ") {
                Task { await todoList.fetchAll() }
            }
            Button("OK", role: .cancel) {
                todoList.clearError()
            }
        } message: {
            Text(todoList.error?.localizedDescription ?? "")
        }
        .task {
            await todoList.fetchAll()
        }
    }
}

/// Todo行の表示
private struct TodoRowView: View {
    let todo: Todo
    let onToggle: () -> Void

    var body: some View {
        HStack {
            Button {
                onToggle()
            } label: {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(todo.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)

            Text(todo.title)
                .strikethrough(todo.isCompleted)
                .foregroundStyle(todo.isCompleted ? .secondary : .primary)
        }
    }
}
