import SwiftUI

public struct GreetingView: View {
    var greeting = UseGreeting()

    public init() {}

    public var body: some View {
        VStack(spacing: 24) {
            TextField("名前を入力", text: greeting.binding.name)
                .textFieldStyle(.roundedBorder)

            Text(greeting.greetingText)
                .font(.title)
        }
        .padding(40)
    }
}
