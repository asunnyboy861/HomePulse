import SwiftUI

struct AppearanceSettingsView: View {
    @EnvironmentObject var settingsViewModel: SettingsViewModel

    var body: some View {
        Form {
            Section {
                ForEach(ThemePreference.allCases, id: \.self) { theme in
                    Button(action: { settingsViewModel.saveTheme(theme) }) {
                        HStack {
                            Image(systemName: theme.iconName)
                                .foregroundStyle(Color.accentColor)
                                .frame(width: 28)
                            Text(theme.label)
                                .font(.body)
                                .foregroundStyle(.primary)
                            Spacer()
                            if settingsViewModel.themePreference == theme {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("Theme")
            } footer: {
                Text("Choose how HomePulse looks. System follows your device's appearance setting.")
                    .font(.caption2)
            }

            Section {
                ForEach(TemperatureUnit.allCases, id: \.self) { unit in
                    Button(action: { settingsViewModel.saveTemperatureUnit(unit) }) {
                        HStack {
                            Image(systemName: unit.iconName)
                                .foregroundStyle(Color.accentColor)
                                .frame(width: 28)
                            Text(unit.label)
                                .font(.body)
                                .foregroundStyle(.primary)
                            Spacer()
                            if settingsViewModel.temperatureUnit == unit {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("Temperature Unit")
            } footer: {
                Text("Choose between Fahrenheit and Celsius for temperature display.")
                    .font(.caption2)
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
}
