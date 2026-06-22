import SwiftUI

struct ConnectionSettingsView: View {
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @State private var haURL: String = ""
    @State private var haToken: String = ""
    @State private var isTesting = false
    @State private var testResult: String?

    var body: some View {
        Form {
            Section {
                HStack {
                    Image(systemName: "house.fill")
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("HomeKit")
                            .font(.body)
                        Text(homeKitStatus)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: homeKitStatusIcon)
                        .foregroundStyle(homeKitStatusColor)
                }
            } header: {
                Text("HomeKit")
            } footer: {
                Text("HomeKit access is managed by iOS Settings.")
                    .font(.caption2)
            }

            Section {
                TextField("Server URL", text: $haURL)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()

                SecureField("Long-Lived Access Token", text: $haToken)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()

                Button(action: testConnection) {
                    HStack {
                        if isTesting {
                            ProgressView()
                                .tint(.accentColor)
                        }
                        Text(isTesting ? "Testing..." : "Test Connection")
                    }
                }
                .disabled(isTesting || haURL.isEmpty || haToken.isEmpty)

                if let result = testResult {
                    Text(result)
                        .font(.caption)
                        .foregroundStyle(result.contains("Success") ? .green : .red)
                }
            } header: {
                Text("Home Assistant")
            } footer: {
                Text("Find your token in Home Assistant → Profile → Long-Lived Access Tokens.")
                    .font(.caption2)
            }

            Section {
                Button(role: .destructive) {
                    settingsViewModel.platformChoice = nil
                    settingsViewModel.haConnected = false
                    UserDefaults.standard.removeObject(forKey: "platformChoice")
                    UserDefaults.standard.removeObject(forKey: "haURL")
                    UserDefaults.standard.removeObject(forKey: "haToken")
                    UserDefaults.standard.removeObject(forKey: "haConnected")
                    haURL = ""
                    haToken = ""
                } label: {
                    Text("Reset All Connections")
                }
            }
        }
        .navigationTitle("Connection")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            haURL = settingsViewModel.haURL
            haToken = settingsViewModel.haToken
        }
    }

    private var homeKitStatus: String {
        HomeKitService.shared.isAuthorized ? "Connected" : "Not authorized"
    }

    private var homeKitStatusIcon: String {
        HomeKitService.shared.isAuthorized ? "checkmark.circle.fill" : "exclamationmark.circle"
    }

    private var homeKitStatusColor: Color {
        HomeKitService.shared.isAuthorized ? .green : .orange
    }

    private func testConnection() {
        guard let url = URL(string: haURL) else {
            testResult = "Invalid URL"
            return
        }

        isTesting = true
        testResult = nil

        Task {
            await HomeAssistantService.shared.configure(url: url, token: haToken)
            do {
                try await HomeAssistantService.shared.connect()
                settingsViewModel.saveHAConfig(url: haURL, token: haToken)
                settingsViewModel.setHAConnected(true)
                testResult = "Success! Connected to Home Assistant."
            } catch {
                settingsViewModel.setHAConnected(false)
                testResult = "Failed: \(error.localizedDescription)"
            }
            isTesting = false
        }
    }
}
