import Foundation
import SwiftData

@Model
final class SensorBucket {
    @Attribute(.unique) var id: String
    var deviceId: String
    var deviceName: String
    var roomName: String
    var kindRaw: String
    var readingsData: Data
    var lastUpdated: Date

    init(deviceId: String, deviceName: String, roomName: String, kindRaw: String) {
        self.id = "\(deviceId)-\(Int(Date().timeIntervalSince1970 / 300) * 300)"
        self.deviceId = deviceId
        self.deviceName = deviceName
        self.roomName = roomName
        self.kindRaw = kindRaw
        self.readingsData = Data()
        self.lastUpdated = Date()
    }

    func addReading(_ value: Double, at date: Date = Date()) {
        var readings = decodedReadings
        readings.append(ReadingPoint(timestamp: date, value: value))
        let cutoff = date.addingTimeInterval(-24 * 3600)
        readings = readings.filter { $0.timestamp >= cutoff }
        if let encoded = try? JSONEncoder().encode(readings) {
            readingsData = encoded
        }
        lastUpdated = date
    }

    var decodedReadings: [ReadingPoint] {
        guard !readingsData.isEmpty,
              let decoded = try? JSONDecoder().decode([ReadingPoint].self, from: readingsData)
        else { return [] }
        return decoded
    }

    var sparklinePoints: [Double] {
        decodedReadings.map { $0.value }
    }
}

struct ReadingPoint: Codable, Equatable {
    let timestamp: Date
    let value: Double
}

@Model
final class DayBucket {
    @Attribute(.unique) var id: String
    var deviceId: String
    var date: Date
    var minValue: Double
    var maxValue: Double
    var avgValue: Double
    var sampleCount: Int

    init(deviceId: String, date: Date, min: Double, max: Double, avg: Double, count: Int) {
        self.id = "\(deviceId)-\(Int(date.timeIntervalSince1970 / 86400))"
        self.deviceId = deviceId
        self.date = date
        self.minValue = min
        self.maxValue = max
        self.avgValue = avg
        self.sampleCount = count
    }
}
