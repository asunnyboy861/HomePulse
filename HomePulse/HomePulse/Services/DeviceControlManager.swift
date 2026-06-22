import Foundation
import UIKit
import Combine

@MainActor
final class DeviceControlManager: ObservableObject {
    static let shared = DeviceControlManager()

    private let homeKitService = HomeKitService.shared
    private var pendingActions: [String: Date] = [:]
    private let debounceInterval: TimeInterval = 0.3

    func toggle(device: UnifiedDevice) async {
        guard canExecute(deviceId: device.id) else { return }
        registerAction(deviceId: device.id)

        let haptic = UIImpactFeedbackGenerator(style: .light)
        haptic.impactOccurred()

        switch device.platform {
        case .homekit:
            await homeKitService.toggleDevice(device.id)
        case .homeAssistant:
            try? await HomeAssistantService.shared.toggleDevice(device.id)
        }
    }

    func setBrightness(_ value: Int, for device: UnifiedDevice) async {
        guard canExecute(deviceId: device.id) else { return }
        registerAction(deviceId: device.id)

        switch device.platform {
        case .homekit:
            await homeKitService.setBrightness(value, for: device.id)
        case .homeAssistant:
            try? await HomeAssistantService.shared.setBrightness(value, for: device.id)
        }
    }

    func setTargetTemperature(_ value: Double, for device: UnifiedDevice) async {
        guard canExecute(deviceId: device.id) else { return }
        registerAction(deviceId: device.id)

        switch device.platform {
        case .homekit:
            await homeKitService.setTargetTemperature(value, for: device.id)
        case .homeAssistant:
            try? await HomeAssistantService.shared.setTargetTemperature(value, for: device.id)
        }
    }

    func executeScene(_ scene: HomeScene) async {
        let haptic = UINotificationFeedbackGenerator()
        haptic.notificationOccurred(.success)

        switch scene.platform {
        case .homekit:
            await homeKitService.executeScene(scene.id)
        case .homeAssistant:
            try? await HomeAssistantService.shared.executeScene(scene.id)
        }
    }

    private func canExecute(deviceId: String) -> Bool {
        guard let lastTime = pendingActions[deviceId] else { return true }
        return Date().timeIntervalSince(lastTime) >= debounceInterval
    }

    private func registerAction(deviceId: String) {
        pendingActions[deviceId] = Date()
    }
}
