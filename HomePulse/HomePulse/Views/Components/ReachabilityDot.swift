import SwiftUI

struct ReachabilityDot: View {
    let isReachable: Bool

    var body: some View {
        Circle()
            .fill(isReachable ? Color.green : Color.red)
            .frame(width: 6, height: 6)
            .accessibilityLabel(isReachable ? "Online" : "Offline")
    }
}

#Preview {
    HStack(spacing: 20) {
        ReachabilityDot(isReachable: true)
        ReachabilityDot(isReachable: false)
    }
    .padding()
}
