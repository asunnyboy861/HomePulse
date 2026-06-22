import SwiftUI
import SwiftData

@main
struct HomePulseApp: App {
    @StateObject private var settingsViewModel = SettingsViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(settingsViewModel)
                .preferredColorScheme(settingsViewModel.themePreference.colorScheme)
                .tint(.accentColor)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var settingsViewModel: SettingsViewModel

    var body: some View {
        Group {
            if settingsViewModel.hasOnboarded {
                DashboardView()
            } else {
                OnboardingView()
            }
        }
    }
}
