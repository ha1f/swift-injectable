import Domain
import SwiftUI

/// Todo統計画面
public struct TodoStatsView: View {
    var todoStats = UseTodoStats()

    public init() {}

    public var body: some View {
        List {
            Section("概要") {
                LabeledContent("合計", value: "\(todoStats.stats.total)")
                LabeledContent("未完了", value: "\(todoStats.stats.active)")
                LabeledContent("完了", value: "\(todoStats.stats.completed)")
            }

            Section("進捗") {
                VStack(alignment: .leading, spacing: 8) {
                    ProgressView(value: todoStats.completionRate)
                    Text("\(Int(todoStats.completionRate * 100))% 完了")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("統計")
        .task {
            await todoStats.todoList.fetchAll()
        }
    }
}
