import SwiftUI

struct NotificationSettingsView: View {
    @StateObject private var notificationService = NotificationService.shared
    @StateObject private var dashboardVM = DashboardViewModel()
    @State private var newMinThreshold: String = ""
    @State private var newMaxThreshold: String = ""
    @State private var selectedDevice: UnifiedDevice?

    var body: some View {
        Form {
            Section {
                if !notificationService.isAuthorized {
                    VStack(spacing: 12) {
                        Image(systemName: "bell.slash")
                            .font(.title)
                            .foregroundStyle(.secondary)
                        Text("Notifications are disabled")
                            .font(.subheadline)
                        Button("Enable Notifications") {
                            Task { await notificationService.requestAuthorization() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                } else {
                    HStack {
                        Image(systemName: "bell.badge.fill")
                            .foregroundStyle(.green)
                        Text("Notifications enabled")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Permission")
            }

            Section {
                let allSensors = dashboardVM.rooms.flatMap { $0.sensors }
                if allSensors.isEmpty {
                    Text("No sensors available. Connect a platform first.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(allSensors) { sensor in
                        sensorThresholdRow(sensor)
                    }
                }
            } header: {
                Text("Sensor Thresholds")
            } footer: {
                Text("Set min/max values. You'll be notified when sensors cross these thresholds.")
                    .font(.caption2)
            }
        }
        .navigationTitle("Anomaly Alerts")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await dashboardVM.loadInitialData()
        }
    }

    private func sensorThresholdRow(_ sensor: UnifiedDevice) -> some View {
        let threshold = notificationService.thresholds.first(where: { $0.deviceId == sensor.id })
        let minValue = threshold?.minValue
        let maxValue = threshold?.maxValue

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: sensor.kind.iconName)
                    .foregroundStyle(sensor.kind.themeColor)
                Text(sensor.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { threshold?.enabled ?? false },
                    set: { newValue in
                        if newValue {
                            notificationService.setThreshold(
                                deviceId: sensor.id,
                                deviceName: sensor.name,
                                min: minValue,
                                max: maxValue
                            )
                        } else {
                            notificationService.toggleThreshold(deviceId: sensor.id, enabled: false)
                        }
                    }
                ))
                .labelsHidden()
                .tint(Color.accentColor)
            }

            if threshold?.enabled == true {
                HStack {
                    TextField("Min", text: Binding(
                        get: { minValue.map { String($0) } ?? "" },
                        set: { newValue in
                            let value = Double(newValue)
                            notificationService.setThreshold(
                                deviceId: sensor.id,
                                deviceName: sensor.name,
                                min: value,
                                max: maxValue
                            )
                        }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)

                    Text("to")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    TextField("Max", text: Binding(
                        get: { maxValue.map { String($0) } ?? "" },
                        set: { newValue in
                            let value = Double(newValue)
                            notificationService.setThreshold(
                                deviceId: sensor.id,
                                deviceName: sensor.name,
                                min: minValue,
                                max: value
                            )
                        }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
