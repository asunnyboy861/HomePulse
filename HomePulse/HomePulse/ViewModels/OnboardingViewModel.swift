import Foundation
import SwiftUI
import Combine

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var currentStep: OnboardingStep = .platform
    @Published var selectedPlatform: Platform?
    @Published var haURL: String = ""
    @Published var haToken: String = ""
    @Published var isConnecting = false
    @Published var connectionError: String?
    @Published var connectionSuccess = false

    private let homeKitService = HomeKitService.shared
    private let haService = HomeAssistantService.shared

    func selectPlatform(_ platform: Platform) {
        selectedPlatform = platform
        UserDefaults.standard.set(platform.rawValue, forKey: "platformChoice")
    }

    func connectHomeKit() async {
        isConnecting = true
        connectionError = nil

        homeKitService.requestAuthorization()

        try? await Task.sleep(nanoseconds: 3_000_000_000)

        if homeKitService.isAuthorized {
            homeKitService.refresh()
            connectionSuccess = true
            currentStep = .ready
        } else {
            connectionError = "HomeKit access was not granted. Please enable HomeKit in Settings."
        }

        isConnecting = false
    }

    func connectHomeAssistant() async {
        guard !haURL.isEmpty, !haToken.isEmpty,
              let url = URL(string: haURL)
        else {
            connectionError = "Please enter a valid URL and token."
            return
        }

        isConnecting = true
        connectionError = nil

        await haService.configure(url: url, token: haToken)

        do {
            try await haService.connect()
            UserDefaults.standard.set(haURL, forKey: "haURL")
            UserDefaults.standard.set(haToken, forKey: "haToken")
            UserDefaults.standard.set(true, forKey: "haConnected")
            connectionSuccess = true
            currentStep = .ready
        } catch {
            connectionError = error.localizedDescription
        }

        isConnecting = false
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasOnboarded")
    }

    func skipOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasOnboarded")
    }
}

enum OnboardingStep {
    case platform
    case connect
    case ready
}
