import SwiftUI

struct BigNumberView: View {
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text(value)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .contentTransition(.numericText())
                .animation(.spring(duration: 0.3), value: value)
            Text(unit)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(color.opacity(0.7))
        }
        .accessibilityLabel("\(value) \(unit)")
    }
}

#Preview {
    VStack(spacing: 16) {
        BigNumberView(value: "72.4", unit: "°F", color: .orange)
        BigNumberView(value: "45", unit: "%", color: .cyan)
        BigNumberView(value: "620", unit: "ppm", color: .purple)
    }
    .padding()
}
