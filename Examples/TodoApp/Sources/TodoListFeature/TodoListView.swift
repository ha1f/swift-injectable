import Domain
import TodoDetailFeature
import SwiftUI

/// Todoリスト画面
public struct TodoListView: View {
    var hook = UseTodoListView()

    public init() {}

    public var body: some View {
        VStack {
            Picker("フィルター", selection: hook.filter.binding.currentFilter) {
                Text("すべて").tag(TodoFilter.all)
                Text("未完了").tag(TodoFilter.active)
                Text("完了").tag(TodoFilter.completed)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            if hook.todoList.isLoading {
                ProgressView()
                    .frame(maxHeight: .infinity)
            } else if hook.filteredTodos.isEmpty {
                ContentUnavailableView(
                    "Todoがありません",
                    systemImage: "checklist"
                )
            } else {
                List {
                    ForEach(hook.filteredTodos) { todo in
                        NavigationLink {
                            TodoDetailView(todo: todo)
                        } label: {
                            TodoRowView(todo: todo) {
                                Task {
                                    await hook.todoList.toggleCompletion(todo)
                                }
                            }
                        }
                    }
                    .onDelete { indexSet in
                        hook.deleteAtOffsets(indexSet)
                    }
                }
            }
        }
        .alert(
            "エラー",
            isPresented: Binding(
                get: { hook.hasError },
                set: { if !$0 { hook.dismissError() } }
            )
        ) {
            Button("リトライ") {
                Task { await hook.retry() }
            }
            Button("OK", role: .cancel) {
                hook.dismissError()
            }
        } message: {
            Text(hook.errorMessage)
        }
        .task {
            await hook.retry()
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
