import SwiftUI

public struct CounterView: View {
    var counterView = UseCounterView()

    public init() {}

    public var body: some View {
        VStack(spacing: 24) {
            Text(counterView.displayText)
                .font(.largeTitle)
                .foregroundStyle(counterView.displayColor)

            HStack(spacing: 16) {
                Button("-") {
                    counterView.counter.decrement()
                }

                Button("Reset") {
                    counterView.counter.reset()
                }

                Button("+") {
                    counterView.counter.increment()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(40)
    }
}
