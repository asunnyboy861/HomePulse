import SwiftUI

struct GlassCardView<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.05), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}

#Preview {
    VStack(spacing: 12) {
        GlassCardView {
            VStack(alignment: .leading) {
                Text("Living Room")
                    .font(.headline)
                Text("72°F • 45% humidity")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        GlassCardView {
            Text("Another card")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
