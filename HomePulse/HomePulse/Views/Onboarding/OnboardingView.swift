import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel()
    @State private var navigateToDashboard = false

    var body: some View {
        NavigationStack {
            VStack {
                switch viewModel.currentStep {
                case .platform:
                    platformSelectionView
                case .connect:
                    connectionView
                case .ready:
                    readyView
                }
            }
            .padding()
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Welcome to HomePulse")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Skip") {
                        viewModel.skipOnboarding()
                        navigateToDashboard = true
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .navigationDestination(isPresented: $navigateToDashboard) {
                DashboardView()
            }
        }
    }

    private var platformSelectionView: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "house.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.accentColor)
                Text("Your home at a glance")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Choose a platform to connect your smart home devices.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                ForEach(Platform.allCases, id: \.self) { platform in
                    Button(action: {
                        viewModel.selectPlatform(platform)
                        viewModel.currentStep = .connect
                    }) {
                        HStack {
                            Image(systemName: platform.iconName)
                                .font(.title2)
                                .frame(width: 32)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(platform.displayName)
                                    .font(.headline)
                                Text(platformDescription(platform))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding(16)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()
        }
    }

    private var connectionView: some View {
        VStack(spacing: 20) {
            Spacer()

            if viewModel.selectedPlatform == .homekit {
                homeKitConnectionView
            } else if viewModel.selectedPlatform == .homeAssistant {
                homeAssistantConnectionView
            }

            if let error = viewModel.connectionError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()
        }
    }

    private var homeKitConnectionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "house.fill")
                .font(.system(size: 50))
                .foregroundStyle(Color.accentColor)

            VStack(spacing: 8) {
                Text("Connect to HomeKit")
                    .font(.title3)
                    .fontWeight(.bold)
                Text("We'll automatically discover your HomeKit accessories. You don't need to enter any URLs or tokens.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: {
                Task {
                    await viewModel.connectHomeKit()
                    if viewModel.connectionSuccess {
                        viewModel.completeOnboarding()
                        navigateToDashboard = true
                    }
                }
            }) {
                HStack {
                    if viewModel.isConnecting {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(viewModel.isConnecting ? "Connecting..." : "Connect HomeKit")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(viewModel.isConnecting)
        }
    }

    private var homeAssistantConnectionView: some View {
        VStack(spacing: 16) {
            Image(systemName: "server.rack")
                .font(.system(size: 50))
                .foregroundStyle(Color.accentColor)

            VStack(spacing: 8) {
                Text("Connect to Home Assistant")
                    .font(.title3)
                    .fontWeight(.bold)
                Text("Enter your server URL and Long-Lived Access Token.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                TextField("http://homeassistant.local:8123", text: $viewModel.haURL)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()

                SecureField("Long-Lived Access Token", text: $viewModel.haToken)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal)

            Button(action: {
                Task {
                    await viewModel.connectHomeAssistant()
                    if viewModel.connectionSuccess {
                        viewModel.completeOnboarding()
                        navigateToDashboard = true
                    }
                }
            }) {
                HStack {
                    if viewModel.isConnecting {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(viewModel.isConnecting ? "Connecting..." : "Connect")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(viewModel.isConnecting || viewModel.haURL.isEmpty || viewModel.haToken.isEmpty)
            .padding(.horizontal)
        }
    }

    private var readyView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 70))
                .foregroundStyle(.green)

            VStack(spacing: 8) {
                Text("You're all set!")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Your home is now connected. Tap continue to view your dashboard.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: {
                viewModel.completeOnboarding()
                navigateToDashboard = true
            }) {
                Text("Continue to Dashboard")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)

            Spacer()
        }
    }

    private func platformDescription(_ platform: Platform) -> String {
        switch platform {
        case .homekit: return "Auto-discovery. Zero setup."
        case .homeAssistant: return "Advanced control. WebSocket real-time."
        }
    }
}

#Preview {
    OnboardingView()
}
