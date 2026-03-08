import Presentation
import Testing

@Suite("UseTodoForm テスト")
@MainActor
struct UseTodoFormTests {

    @Test("初期状態: タイトルが空でisValidがfalse")
    func initialState() {
        let form = UseTodoForm()
        #expect(form.title == "")
        #expect(form.isValid == false)
        #expect(form.isSubmitting == false)
    }

    @Test("タイトルが入力されるとisValidがtrueになる")
    func validTitle() {
        let form = UseTodoForm()
        form.title = "有効なタイトル"
        #expect(form.isValid == true)
        #expect(form.validationError == nil)
    }

    @Test("スペースのみのタイトルはisValidがfalse")
    func whitespaceOnly() {
        let form = UseTodoForm()
        form.title = "   "
        #expect(form.isValid == false)
        #expect(form.validationError == "タイトルを入力してください")
    }

    @Test("空文字の場合はvalidationErrorがnil（まだ入力していない状態）")
    func emptyNoError() {
        let form = UseTodoForm()
        #expect(form.validationError == nil)
    }

    @Test("resetでフォームがクリアされる")
    func reset() {
        let form = UseTodoForm()
        form.title = "テスト"
        form.isSubmitting = true

        form.reset()

        #expect(form.title == "")
        #expect(form.isSubmitting == false)
    }
}
