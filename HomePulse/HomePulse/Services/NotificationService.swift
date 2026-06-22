import Foundation
import UserNotifications
import Combine

final class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published var thresholds: [SensorThreshold] = []
    @Published var isAuthorized = false

    private let thresholdKey = "sensorThresholds"

    init() {
        loadThresholds()
        checkAuthorization()
    }

    func requestAuthorization() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
        } catch {
            isAuthorized = false
        }
    }

    private func checkAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    func setThreshold(deviceId: String, deviceName: String, min: Double?, max: Double?) {
        if let index = thresholds.firstIndex(where: { $0.deviceId == deviceId }) {
            thresholds[index].minValue = min
            thresholds[index].maxValue = max
            thresholds[index].enabled = true
        } else {
            thresholds.append(SensorThreshold(
                deviceId: deviceId,
                deviceName: deviceName,
                minValue: min,
                maxValue: max,
                enabled: true
            ))
        }
        saveThresholds()
    }

    func removeThreshold(deviceId: String) {
        thresholds.removeAll { $0.deviceId == deviceId }
        saveThresholds()
    }

    func toggleThreshold(deviceId: String, enabled: Bool) {
        if let index = thresholds.firstIndex(where: { $0.deviceId == deviceId }) {
            thresholds[index].enabled = enabled
            saveThresholds()
        }
    }

    func checkThreshold(deviceId: String, deviceName: String, value: Double) {
        guard let threshold = thresholds.first(where: { $0.deviceId == deviceId && $0.enabled }) else { return }

        if let min = threshold.minValue, value < min {
            sendNotification(
                title: "Low Alert: \(deviceName)",
                body: "Current value \(String(format: "%.1f", value)) is below threshold \(String(format: "%.1f", min))"
            )
        }

        if let max = threshold.maxValue, value > max {
            sendNotification(
                title: "High Alert: \(deviceName)",
                body: "Current value \(String(format: "%.1f", value)) is above threshold \(String(format: "%.1f", max))"
            )
        }
    }

    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { _ in }
    }

    private func saveThresholds() {
        if let encoded = try? JSONEncoder().encode(thresholds) {
            UserDefaults.standard.set(encoded, forKey: thresholdKey)
        }
    }

    private func loadThresholds() {
        guard let data = UserDefaults.standard.data(forKey: thresholdKey),
              let decoded = try? JSONDecoder().decode([SensorThreshold].self, from: data)
        else { return }
        thresholds = decoded
    }
}
