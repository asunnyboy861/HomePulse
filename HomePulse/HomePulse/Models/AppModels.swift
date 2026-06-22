import Foundation
import SwiftUI

enum Platform: String, Codable, CaseIterable {
    case homekit
    case homeAssistant

    var displayName: String {
        switch self {
        case .homekit: return "HomeKit"
        case .homeAssistant: return "Home Assistant"
        }
    }

    var iconName: String {
        switch self {
        case .homekit: return "house.fill"
        case .homeAssistant: return "server.rack"
        }
    }
}

enum DeviceKind: String, Codable, CaseIterable {
    case temperatureSensor
    case humiditySensor
    case light
    case thermostat
    case lock
    case switchDevice
    case fan
    case co2Sensor
    case airQualitySensor
    case motionSensor
    case occupancySensor
    case contactSensor
    case battery
    case unknown

    var displayName: String {
        switch self {
        case .temperatureSensor: return "Temperature"
        case .humiditySensor: return "Humidity"
        case .light: return "Light"
        case .thermostat: return "Thermostat"
        case .lock: return "Lock"
        case .switchDevice: return "Switch"
        case .fan: return "Fan"
        case .co2Sensor: return "CO₂"
        case .airQualitySensor: return "Air Quality"
        case .motionSensor: return "Motion"
        case .occupancySensor: return "Occupancy"
        case .contactSensor: return "Contact"
        case .battery: return "Battery"
        case .unknown: return "Device"
        }
    }

    var iconName: String {
        switch self {
        case .temperatureSensor: return "thermometer"
        case .humiditySensor: return "humidity.fill"
        case .light: return "lightbulb.fill"
        case .thermostat: return "thermostat"
        case .lock: return "lock.fill"
        case .switchDevice: return "power"
        case .fan: return "fanblades.fill"
        case .co2Sensor: return "wind"
        case .airQualitySensor: return "leaf.fill"
        case .motionSensor: return "motion.fill"
        case .occupancySensor: return "person.fill"
        case .contactSensor: return "door.left.hand.open"
        case .battery: return "battery.100"
        case .unknown: return "questionmark.circle"
        }
    }

    var themeColor: Color {
        switch self {
        case .temperatureSensor: return .orange
        case .humiditySensor: return .cyan
        case .light: return .yellow
        case .thermostat: return .red
        case .lock: return .indigo
        case .switchDevice: return .blue
        case .fan: return .teal
        case .co2Sensor: return .purple
        case .airQualitySensor: return .green
        case .motionSensor, .occupancySensor: return .pink
        case .contactSensor: return .brown
        case .battery: return .green
        case .unknown: return .gray
        }
    }

    var isSensor: Bool {
        switch self {
        case .temperatureSensor, .humiditySensor, .co2Sensor, .airQualitySensor,
             .motionSensor, .occupancySensor, .contactSensor, .battery:
            return true
        default:
            return false
        }
    }
}

enum DeviceState: Equatable, Hashable {
    case power(Bool)
    case brightness(Int)
    case temperature(Double)
    case humidity(Double)
    case co2(Double)
    case locked(Bool)
    case motion(Bool)
    case contact(Bool)
    case battery(Int)
    case unknown
}

struct UnifiedDevice: Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let roomName: String
    let platform: Platform
    let kind: DeviceKind
    var state: DeviceState
    var isReachable: Bool
    var lastUpdated: Date

    var displayValue: String {
        switch state {
        case .power(let on): return on ? "On" : "Off"
        case .brightness(let value): return "\(value)%"
        case .temperature(let value): return String(format: "%.1f°", value)
        case .humidity(let value): return String(format: "%.0f%%", value)
        case .co2(let value): return "\(Int(value)) ppm"
        case .locked(let locked): return locked ? "Locked" : "Unlocked"
        case .motion(let detected): return detected ? "Motion" : "Clear"
        case .contact(let open): return open ? "Open" : "Closed"
        case .battery(let value): return "\(value)%"
        case .unknown: return "—"
        }
    }

    var numericValue: Double? {
        switch state {
        case .temperature(let v): return v
        case .humidity(let v): return v
        case .co2(let v): return v
        case .battery(let v): return Double(v)
        case .brightness(let v): return Double(v)
        default: return nil
        }
    }
}

struct HomeRoom: Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    var devices: [UnifiedDevice]

    var sensors: [UnifiedDevice] { devices.filter { $0.kind.isSensor } }
    var lights: [UnifiedDevice] { devices.filter { $0.kind == .light } }
    var controllables: [UnifiedDevice] { devices.filter { $0.kind != .unknown && !$0.kind.isSensor } }
    var lightsOnCount: Int { lights.filter { if case .power(let on) = $0.state { return on } else if case .brightness(let b) = $0.state { return b > 0 } else { return false } }.count }
}

struct HomeScene: Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let platform: Platform
    var iconName: String
}

struct SensorThreshold: Codable, Equatable, Identifiable {
    var id: String { deviceId }
    let deviceId: String
    let deviceName: String
    var minValue: Double?
    var maxValue: Double?
    var enabled: Bool
}

struct SensorReading: Identifiable, Equatable {
    let id: String
    let deviceId: String
    let value: Double
    let unit: String
    let timestamp: Date
}
