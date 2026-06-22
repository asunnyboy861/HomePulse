import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @StateObject private var purchaseManager = PurchaseManager.shared
    @StateObject private var notificationService = NotificationService.shared
    @State private var showPaywall = false
    @State private var showContactSupport = false
    @State private var showConnectionSettings = false
    @State private var showAppearanceSettings = false
    @State private var showNotificationSettings = false
    @State private var showDataExport = false
    @State private var showAbout = false

    private let githubUser = "asunnyboy861"
    private let appName = "HomePulse"

    var body: some View {
        Form {
            connectionSection
            appearanceSection
            proSection
            notificationsSection
            dataExportSection
            aboutSection
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .sheet(isPresented: $showContactSupport) { ContactSupportView() }
        .navigationDestination(isPresented: $showConnectionSettings) { ConnectionSettingsView() }
        .navigationDestination(isPresented: $showAppearanceSettings) { AppearanceSettingsView() }
        .navigationDestination(isPresented: $showNotificationSettings) { NotificationSettingsView() }
        .navigationDestination(isPresented: $showDataExport) { DataExportView() }
        .navigationDestination(isPresented: $showAbout) { AboutView() }
    }

    private var connectionSection: some View {
        Section {
            NavigationLink(destination: ConnectionSettingsView()) {
                HStack {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Connection")
                            .font(.body)
                        Text(connectionStatusText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        } header: {
            Text("Platform")
        }
    }

    private var connectionStatusText: String {
        var parts: [String] = []
        if settingsViewModel.platformChoice == .homekit {
            parts.append("HomeKit Connected")
        }
        if settingsViewModel.haConnected {
            parts.append("Home Assistant Connected")
        }
        if parts.isEmpty {
            return "Not configured"
        }
        return parts.joined(separator: " • ")
    }

    private var appearanceSection: some View {
        Section {
            NavigationLink(destination: AppearanceSettingsView()) {
                HStack {
                    Image(systemName: settingsViewModel.themePreference.iconName)
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Appearance")
                            .font(.body)
                        Text("\(settingsViewModel.themePreference.label) • \(settingsViewModel.temperatureUnit.label)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        } header: {
            Text("Display")
        }
    }

    private var proSection: some View {
        Section {
            if purchaseManager.isPro {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Pro Active")
                            .font(.body)
                            .fontWeight(.medium)
                        Text("All features unlocked")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            } else {
                Button(action: { showPaywall = true }) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Upgrade to Pro")
                                .font(.body)
                                .fontWeight(.medium)
                            Text("Unlock charts, alerts, iCloud sync")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }
                .buttonStyle(.plain)
            }

            Button(action: {
                Task { await purchaseManager.restorePurchases() }
            }) {
                Text("Restore Purchases")
                    .font(.body)
            }
        } header: {
            Text("Pro")
        }
    }

    private var notificationsSection: some View {
        Section {
            NavigationLink(destination: NotificationSettingsView()) {
                HStack {
                    Image(systemName: "bell.badge")
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Anomaly Alerts")
                            .font(.body)
                        Text(notificationStatusText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        } header: {
            Text("Notifications")
        } footer: {
            Text("Get notified when sensors exceed your configured thresholds.")
                .font(.caption2)
        }
    }

    private var notificationStatusText: String {
        if !notificationService.isAuthorized {
            return "Notifications disabled"
        }
        let count = notificationService.thresholds.filter { $0.enabled }.count
        return count == 0 ? "No alerts configured" : "\(count) alert\(count == 1 ? "" : "s") active"
    }

    private var dataExportSection: some View {
        Section {
            NavigationLink(destination: DataExportView()) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Data Export")
                            .font(.body)
                        Text("Export sensor history as CSV")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if !purchaseManager.isPro {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }
            }
            .disabled(!purchaseManager.isPro)
        } header: {
            Text("Data")
        } footer: {
            if !purchaseManager.isPro {
                Text("Pro feature. Upgrade to export sensor data.")
                    .font(.caption2)
            }
        }
    }

    private var aboutSection: some View {
        Section {
            Button(action: { showContactSupport = true }) {
                HStack {
                    Image(systemName: "envelope")
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 28)
                    Text("Contact Support")
                        .font(.body)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
            .buttonStyle(.plain)

            NavigationLink(destination: AboutView()) {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 28)
                    Text("About")
                        .font(.body)
                }
            }

            Link(destination: URL(string: "https://\(githubUser).github.io/\(appName)/support.html")!) {
                HStack {
                    Image(systemName: "lifepreserver")
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 28)
                    Text("Support Page")
                        .font(.body)
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }

            Link(destination: URL(string: "https://\(githubUser).github.io/\(appName)/privacy.html")!) {
                HStack {
                    Image(systemName: "hand.raised")
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 28)
                    Text("Privacy Policy")
                        .font(.body)
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }

            Link(destination: URL(string: "https://\(githubUser).github.io/\(appName)/terms.html")!) {
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 28)
                    Text("Terms of Use")
                        .font(.body)
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
        } header: {
            Text("About & Legal")
        } footer: {
            Text(settingsViewModel.appVersion)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}
