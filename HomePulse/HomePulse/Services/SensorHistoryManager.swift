import Foundation
import SwiftData
import SwiftUI
import Combine

@MainActor
final class SensorHistoryManager: ObservableObject {
    static let shared = SensorHistoryManager()

    private let modelContainer: ModelContainer?
    private let modelContext: ModelContext?

    init() {
        do {
            let schema = Schema([SensorBucket.self, DayBucket.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [config])
            modelContext = modelContainer?.mainContext
        } catch {
            modelContainer = nil
            modelContext = nil
        }
    }

    var container: ModelContainer? { modelContainer }

    func recordReading(deviceId: String, deviceName: String, roomName: String, kind: DeviceKind, value: Double) {
        guard let modelContext else { return }

        let kindRaw = kind.rawValue
        let bucketId = "\(deviceId)-\(Int(Date().timeIntervalSince1970 / 300) * 300)"

        let descriptor = FetchDescriptor<SensorBucket>(
            predicate: #Predicate { $0.id == bucketId }
        )

        if let existing = try? modelContext.fetch(descriptor).first {
            existing.addReading(value)
        } else {
            let bucket = SensorBucket(deviceId: deviceId, deviceName: deviceName, roomName: roomName, kindRaw: kindRaw)
            bucket.addReading(value)
            modelContext.insert(bucket)
        }

        try? modelContext.save()
    }

    func getSparklineData(deviceId: String) -> [ReadingPoint] {
        guard let modelContext else { return [] }

        let cutoff = Date().addingTimeInterval(-24 * 3600)
        let descriptor = FetchDescriptor<SensorBucket>(
            predicate: #Predicate { $0.deviceId == deviceId && $0.lastUpdated >= cutoff },
            sortBy: [SortDescriptor(\.lastUpdated)]
        )

        guard let buckets = try? modelContext.fetch(descriptor) else { return [] }
        var allPoints: [ReadingPoint] = []
        for bucket in buckets {
            allPoints.append(contentsOf: bucket.decodedReadings)
        }
        return allPoints.downsample(maxPoints: 50)
    }

    func getHistoryData(deviceId: String, days: Int) -> [ReadingPoint] {
        guard let modelContext else { return [] }

        let cutoff = Date().addingTimeInterval(-Double(days) * 86400)
        let descriptor = FetchDescriptor<SensorBucket>(
            predicate: #Predicate { $0.deviceId == deviceId && $0.lastUpdated >= cutoff },
            sortBy: [SortDescriptor(\.lastUpdated)]
        )

        guard let buckets = try? modelContext.fetch(descriptor) else { return [] }
        var allPoints: [ReadingPoint] = []
        for bucket in buckets {
            allPoints.append(contentsOf: bucket.decodedReadings)
        }

        if days <= 1 {
            return allPoints.downsample(maxPoints: 168)
        } else if days <= 7 {
            return aggregateHourly(allPoints)
        } else {
            return aggregateDaily(allPoints)
        }
    }

    private func aggregateHourly(_ points: [ReadingPoint]) -> [ReadingPoint] {
        let calendar = Calendar.current
        var grouped: [Date: [Double]] = [:]

        for point in points {
            let hour = calendar.dateInterval(of: .hour, for: point.timestamp)?.start ?? point.timestamp
            grouped[hour, default: []].append(point.value)
        }

        return grouped.map { date, values in
            ReadingPoint(timestamp: date, value: values.reduce(0, +) / Double(values.count))
        }.sorted { $0.timestamp < $1.timestamp }
    }

    private func aggregateDaily(_ points: [ReadingPoint]) -> [ReadingPoint] {
        let calendar = Calendar.current
        var grouped: [Date: [Double]] = [:]

        for point in points {
            let day = calendar.startOfDay(for: point.timestamp)
            grouped[day, default: []].append(point.value)
        }

        return grouped.map { date, values in
            ReadingPoint(timestamp: date, value: values.reduce(0, +) / Double(values.count))
        }.sorted { $0.timestamp < $1.timestamp }
    }

    func getStats(deviceId: String, days: Int) -> (min: Double?, max: Double?, avg: Double?) {
        let points = getHistoryData(deviceId: deviceId, days: days)
        return (points.minValue, points.maxValue, points.avgValue)
    }

    func exportCSV(deviceId: String, days: Int) -> String? {
        let points = getHistoryData(deviceId: deviceId, days: days)
        guard !points.isEmpty else { return nil }

        var csv = "Timestamp,Value\n"
        let formatter = ISO8601DateFormatter()
        for point in points {
            csv += "\(formatter.string(from: point.timestamp)),\(point.value)\n"
        }
        return csv
    }

    func sampleAllSensors(devices: [UnifiedDevice]) {
        for device in devices {
            if let value = device.numericValue {
                recordReading(
                    deviceId: device.id,
                    deviceName: device.name,
                    roomName: device.roomName,
                    kind: device.kind,
                    value: value
                )
            }
        }
    }
}
