import SwiftUI

struct AboutView: View {
    @EnvironmentObject var settingsViewModel: SettingsViewModel

    private let githubUser = "asunnyboy861"
    private let appName = "HomePulse"

    var body: some View {
        Form {
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(Color.accentColor)

                    Text("HomePulse")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(settingsViewModel.appVersion)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Your home at a glance")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            }

            Section {
                Link(destination: URL(string: "https://\(githubUser).github.io/\(appName)/privacy.html")!) {
                    HStack {
                        Text("Privacy Policy")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundStyle(.secondary)
                    }
                }
                Link(destination: URL(string: "https://\(githubUser).github.io/\(appName)/terms.html")!) {
                    HStack {
                        Text("Terms of Use")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundStyle(.secondary)
                    }
                }
                Link(destination: URL(string: "https://\(githubUser).github.io/\(appName)/support.html")!) {
                    HStack {
                        Text("Support Page")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Legal")
            }

            Section {
                Text("HomePulse is a minimalist smart home dashboard that gives you a single-screen view of your home's sensors and devices. Connect HomeKit or Home Assistant to get started.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("About")
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}
