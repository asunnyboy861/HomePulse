import Foundation
import SwiftUI
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var isPro: Bool = false
    @Published var themePreference: ThemePreference = .system
    @Published var temperatureUnit: TemperatureUnit = .fahrenheit
    @Published var platformChoice: Platform?
    @Published var haURL: String = ""
    @Published var haToken: String = ""
    @Published var haConnected: Bool = false

    private let purchaseManager = PurchaseManager.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        loadSettings()
        purchaseManager.$isPro
            .receive(on: RunLoop.main)
            .assign(to: &$isPro)

        purchaseManager.$isPro
            .sink { [weak self] pro in
                self?.isPro = pro
            }
            .store(in: &cancellables)
    }

    func loadSettings() {
        themePreference = ThemePreference(rawValue: UserDefaults.standard.integer(forKey: "themePreference")) ?? .system
        temperatureUnit = TemperatureUnit(rawValue: UserDefaults.standard.string(forKey: "tempUnit") ?? "fahrenheit") ?? .fahrenheit

        if let platformStr = UserDefaults.standard.string(forKey: "platformChoice") {
            platformChoice = Platform(rawValue: platformStr)
        }

        haURL = UserDefaults.standard.string(forKey: "haURL") ?? ""
        haToken = UserDefaults.standard.string(forKey: "haToken") ?? ""
        haConnected = UserDefaults.standard.bool(forKey: "haConnected")
    }

    func saveTheme(_ theme: ThemePreference) {
        themePreference = theme
        UserDefaults.standard.set(theme.rawValue, forKey: "themePreference")
    }

    func saveTemperatureUnit(_ unit: TemperatureUnit) {
        temperatureUnit = unit
        UserDefaults.standard.set(unit.rawValue, forKey: "tempUnit")
    }

    func savePlatformChoice(_ platform: Platform) {
        platformChoice = platform
        UserDefaults.standard.set(platform.rawValue, forKey: "platformChoice")
    }

    func saveHAConfig(url: String, token: String) {
        haURL = url
        haToken = token
        UserDefaults.standard.set(url, forKey: "haURL")
        UserDefaults.standard.set(token, forKey: "haToken")
    }

    func setHAConnected(_ connected: Bool) {
        haConnected = connected
        UserDefaults.standard.set(connected, forKey: "haConnected")
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasOnboarded")
    }

    var hasOnboarded: Bool {
        UserDefaults.standard.bool(forKey: "hasOnboarded")
    }

    var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }
}

enum ThemePreference: Int, CaseIterable {
    case system = 0
    case light = 1
    case dark = 2

    var label: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var iconName: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum TemperatureUnit: String, CaseIterable {
    case fahrenheit = "fahrenheit"
    case celsius = "celsius"

    var label: String {
        switch self {
        case .fahrenheit: return "°F"
        case .celsius: return "°C"
        }
    }

    var iconName: String {
        switch self {
        case .fahrenheit: return "thermometer.sun"
        case .celsius: return "thermometer.snowflake"
        }
    }

    func convert(_ value: Double) -> Double {
        switch self {
        case .fahrenheit:
            return value * 9 / 5 + 32
        case .celsius:
            return (value - 32) * 5 / 9
        }
    }

    func format(_ value: Double) -> String {
        let converted = convert(value)
        return String(format: "%.1f%@", converted, label)
    }
}
