import Foundation
import HomeKit
import Combine

final class HomeKitService: NSObject, ObservableObject {
    static let shared = HomeKitService()

    @Published private(set) var homes: [HMHome] = []
    @Published private(set) var rooms: [HomeRoom] = []
    @Published private(set) var scenes: [HomeScene] = []
    @Published private(set) var isAuthorized = false

    private var homeManager: HMHomeManager?

    override init() {
        super.init()
    }

    func start() {
        guard homeManager == nil else { return }
        homeManager = HMHomeManager()
        homeManager?.delegate = self
    }

    func requestAuthorization() {
        start()
    }

    func refresh() {
        guard let homeManager else { return }
        isAuthorized = homeManager.authorizationStatus == .authorized
        homes = homeManager.homes
        buildUnifiedDevices()
    }

    private func buildUnifiedDevices() {
        var newRooms: [HomeRoom] = []
        var newScenes: [HomeScene] = []

        for home in homes {
            for room in home.rooms {
                let devices = room.accessories.compactMap { accessory -> UnifiedDevice? in
                    guard accessory.isReachable else { return nil }
                    return mapAccessory(accessory, roomName: room.name)
                }
                if !devices.isEmpty {
                    newRooms.append(HomeRoom(id: "\(home.name)-\(room.name)", name: room.name, devices: devices))
                }
            }

            for actionSet in home.actionSets {
                newScenes.append(HomeScene(
                    id: actionSet.uniqueIdentifier.uuidString,
                    name: actionSet.name,
                    platform: .homekit,
                    iconName: sceneIcon(for: actionSet.name)
                ))
            }
        }

        rooms = newRooms
        scenes = newScenes
    }

    private func mapAccessory(_ accessory: HMAccessory, roomName: String) -> UnifiedDevice? {
        for service in accessory.services {
            for characteristic in service.characteristics {
                switch characteristic.characteristicType {
                case HMCharacteristicTypeCurrentTemperature:
                    if let value = characteristic.value as? Double {
                        return UnifiedDevice(
                            id: accessory.uniqueIdentifier.uuidString,
                            name: accessory.name,
                            roomName: roomName,
                            platform: .homekit,
                            kind: .temperatureSensor,
                            state: .temperature(value),
                            isReachable: accessory.isReachable,
                            lastUpdated: Date()
                        )
                    }
                case HMCharacteristicTypeCurrentRelativeHumidity:
                    if let value = characteristic.value as? Double {
                        return UnifiedDevice(
                            id: accessory.uniqueIdentifier.uuidString,
                            name: accessory.name,
                            roomName: roomName,
                            platform: .homekit,
                            kind: .humiditySensor,
                            state: .humidity(value),
                            isReachable: accessory.isReachable,
                            lastUpdated: Date()
                        )
                    }
                case HMCharacteristicTypePowerState:
                    let on = (characteristic.value as? Bool) ?? false
                    let kind: DeviceKind = service.serviceType == HMServiceTypeLightbulb ? .light : .switchDevice
                    return UnifiedDevice(
                        id: accessory.uniqueIdentifier.uuidString,
                        name: accessory.name,
                        roomName: roomName,
                        platform: .homekit,
                        kind: kind,
                        state: .power(on),
                        isReachable: accessory.isReachable,
                        lastUpdated: Date()
                    )
                case HMCharacteristicTypeBrightness:
                    let brightness = (characteristic.value as? Int) ?? 0
                    return UnifiedDevice(
                        id: accessory.uniqueIdentifier.uuidString,
                        name: accessory.name,
                        roomName: roomName,
                        platform: .homekit,
                        kind: .light,
                        state: .brightness(brightness),
                        isReachable: accessory.isReachable,
                        lastUpdated: Date()
                    )
                case HMCharacteristicTypeTargetLockMechanismState:
                    let locked = (characteristic.value as? Int) ?? 0 == 1
                    return UnifiedDevice(
                        id: accessory.uniqueIdentifier.uuidString,
                        name: accessory.name,
                        roomName: roomName,
                        platform: .homekit,
                        kind: .lock,
                        state: .locked(locked),
                        isReachable: accessory.isReachable,
                        lastUpdated: Date()
                    )
                default:
                    continue
                }
            }
        }

        return UnifiedDevice(
            id: accessory.uniqueIdentifier.uuidString,
            name: accessory.name,
            roomName: roomName,
            platform: .homekit,
            kind: .unknown,
            state: .unknown,
            isReachable: accessory.isReachable,
            lastUpdated: Date()
        )
    }

    private func sceneIcon(for name: String) -> String {
        let lower = name.lowercased()
        if lower.contains("movie") || lower.contains("tv") { return "film.fill" }
        if lower.contains("night") || lower.contains("sleep") { return "moon.stars.fill" }
        if lower.contains("day") || lower.contains("morning") { return "sun.max.fill" }
        if lower.contains("home") || lower.contains("arrive") { return "house.fill" }
        if lower.contains("away") || lower.contains("leave") { return "figure.walk" }
        return "sparkles"
    }

    func toggleDevice(_ deviceId: String) async {
        guard let home = homes.first(where: { home in
            home.rooms.contains { room in
                room.accessories.contains { $0.uniqueIdentifier.uuidString == deviceId }
            }
        }) else { return }

        for room in home.rooms {
            for accessory in room.accessories where accessory.uniqueIdentifier.uuidString == deviceId {
                for service in accessory.services {
                    for characteristic in service.characteristics where characteristic.characteristicType == HMCharacteristicTypePowerState {
                        let current = (characteristic.value as? Bool) ?? false
                        try? await characteristic.writeValue(!current)
                        return
                    }
                }
            }
        }
    }

    func setBrightness(_ value: Int, for deviceId: String) async {
        guard let home = homes.first(where: { home in
            home.rooms.contains { room in
                room.accessories.contains { $0.uniqueIdentifier.uuidString == deviceId }
            }
        }) else { return }

        for room in home.rooms {
            for accessory in room.accessories where accessory.uniqueIdentifier.uuidString == deviceId {
                for service in accessory.services {
                    for characteristic in service.characteristics where characteristic.characteristicType == HMCharacteristicTypeBrightness {
                        try? await characteristic.writeValue(value)
                        return
                    }
                }
            }
        }
    }

    func setTargetTemperature(_ value: Double, for deviceId: String) async {
        guard let home = homes.first(where: { home in
            home.rooms.contains { room in
                room.accessories.contains { $0.uniqueIdentifier.uuidString == deviceId }
            }
        }) else { return }

        for room in home.rooms {
            for accessory in room.accessories where accessory.uniqueIdentifier.uuidString == deviceId {
                for service in accessory.services {
                    for characteristic in service.characteristics where characteristic.characteristicType == HMCharacteristicTypeTargetTemperature {
                        try? await characteristic.writeValue(value)
                        return
                    }
                }
            }
        }
    }

    func executeScene(_ sceneId: String) async {
        for home in homes {
            for actionSet in home.actionSets where actionSet.uniqueIdentifier.uuidString == sceneId {
                try? await home.executeActionSet(actionSet)
                return
            }
        }
    }
}

extension HomeKitService: HMHomeManagerDelegate {
    nonisolated func homeManagerDidUpdateHomes(_ homeManager: HMHomeManager) {
        Task { @MainActor in
            self.refresh()
        }
    }

    nonisolated func homeManager(_ homeManager: HMHomeManager, didUpdate status: HMHomeManagerAuthorizationStatus) {
        Task { @MainActor in
            self.isAuthorized = status == .authorized
        }
    }
}
