import SwiftUI

extension Color {
    static let tempColor = Color.orange
    static let humidityColor = Color.cyan
    static let lightColor = Color.yellow
    static let co2Color = Color.purple
    static let successColor = Color.green
    static let dangerColor = Color.red

    static func sensorColor(for kind: DeviceKind) -> Color {
        kind.themeColor
    }
}

extension Double {
    var formattedTemperature: String {
        String(format: "%.1f°", self)
    }

    var formattedHumidity: String {
        String(format: "%.0f%%", self)
    }

    var formattedCO2: String {
        "\(Int(self)) ppm"
    }
}

extension Date {
    var timeAgo: String {
        let interval = Date().timeIntervalSince(self)
        if interval < 60 { return "Just now" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        return "\(Int(interval / 86400))d ago"
    }

    func bucketKey(interval: TimeInterval) -> String {
        String(format: "%.0f", floor(timeIntervalSince1970 / interval) * interval)
    }

    var hourLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        return formatter.string(from: self).lowercased()
    }

    var dayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: self)
    }
}

extension Array where Element == ReadingPoint {
    func downsample(maxPoints: Int) -> [ReadingPoint] {
        guard count > maxPoints else { return self }
        let step = count / maxPoints
        return stride(from: 0, to: count, by: step).map { self[$0] }
    }

    var minValue: Double? { isEmpty ? nil : map(\.value).min() }
    var maxValue: Double? { isEmpty ? nil : map(\.value).max() }
    var avgValue: Double? {
        guard !isEmpty else { return nil }
        return map(\.value).reduce(0, +) / Double(count)
    }
}
