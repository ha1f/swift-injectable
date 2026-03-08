import SwiftUI

/// Todo追加フォーム画面
public struct TodoFormView: View {
    var form = UseTodoForm()
    let onSubmit: (String) -> Void

    public init(onSubmit: @escaping (String) -> Void) {
        self.onSubmit = onSubmit
    }

    public var body: some View {
        Form {
            Section {
                TextField("タイトル", text: Binding(
                    get: { form.title },
                    set: { form.title = $0 }
                ))
            } footer: {
                if let error = form.validationError {
                    Text(error)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("新しいTodo")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("キャンセル") {
                    form.reset()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("追加") {
                    let title = form.title.trimmingCharacters(in: .whitespacesAndNewlines)
                    form.reset()
                    onSubmit(title)
                }
                .disabled(!form.isValid)
            }
        }
    }
}
