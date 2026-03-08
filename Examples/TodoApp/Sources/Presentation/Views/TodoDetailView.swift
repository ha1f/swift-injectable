import Domain
import SwiftUI

/// Todo詳細画面
public struct TodoDetailView: View {
    let todo: Todo

    public init(todo: Todo) {
        self.todo = todo
    }

    public var body: some View {
        List {
            Section("詳細") {
                LabeledContent("タイトル", value: todo.title)
                LabeledContent("状態", value: todo.isCompleted ? "完了" : "未完了")
                LabeledContent("作成日", value: todo.createdAt.formatted(date: .abbreviated, time: .shortened))
            }

            Section("ID") {
                Text(todo.id.uuidString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(todo.title)
    }
}
