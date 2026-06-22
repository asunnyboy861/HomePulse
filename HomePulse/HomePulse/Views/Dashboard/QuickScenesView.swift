import SwiftUI

struct QuickScenesView: View {
    let scenes: [HomeScene]
    let onSceneTapped: (HomeScene) -> Void

    var body: some View {
        if scenes.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text("Quick Scenes")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(scenes) { scene in
                            Button(action: { onSceneTapped(scene) }) {
                                VStack(spacing: 6) {
                                    Image(systemName: scene.iconName)
                                        .font(.title2)
                                        .foregroundStyle(.white)
                                        .frame(width: 44, height: 44)
                                        .background(Color.accentColor.gradient)
                                        .clipShape(Circle())

                                    Text(scene.name)
                                        .font(.caption2)
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                        .frame(maxWidth: 80)
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Activate scene \(scene.name)")
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}
