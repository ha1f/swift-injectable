import Domain
import SwiftHooks
import SwiftUI

/// Todoフォームの入力状態を管理するhook
@Hook
@MainActor
public struct UseTodoForm {
    public var title: String = ""
    public var isSubmitting: Bool = false

    /// タイトルが空でないかバリデーション
    public var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// バリデーションエラーメッセージ
    public var validationError: String? {
        if title.isEmpty { return nil }
        if !isValid { return "タイトルを入力してください" }
        return nil
    }

    /// フォームをリセットする
    public func reset() {
        title = ""
        isSubmitting = false
    }
}
