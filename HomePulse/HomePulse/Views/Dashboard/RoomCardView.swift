import SwiftUI

struct RoomCardView: View {
    let room: HomeRoom
    let temperatureUnit: TemperatureUnit
    let sparklineData: [String: [Double]]
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "house.fill")
                        .foregroundStyle(Color.accentColor)
                    Text(room.name)
                        .font(.headline)
                    Spacer()
                    if room.lightsOnCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "lightbulb.fill")
                                .font(.caption)
                                .foregroundStyle(.yellow)
                            Text("\(room.lightsOnCount)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if !room.sensors.isEmpty {
                    LazyVGrid(columns: gridColumns, spacing: 12) {
                        ForEach(Array(room.sensors.prefix(4))) { sensor in
                            sensorMiniView(sensor)
                        }
                    }
                }

                if !room.controllables.isEmpty {
                    HStack {
                        ForEach(Array(room.controllables.prefix(3))) { device in
                            HStack(spacing: 4) {
                                Image(systemName: device.kind.iconName)
                                    .font(.caption2)
                                    .foregroundStyle(device.kind.themeColor)
                                Text(device.displayValue)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        if room.controllables.count > 3 {
                            Text("+\(room.controllables.count - 3)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Room \(room.name), \(room.sensors.count) sensors, \(room.lightsOnCount) lights on")
        .accessibilityHint("Tap to view room details")
    }

    private var gridColumns: [GridItem] {
        if room.sensors.count <= 2 {
            return [GridItem(.flexible()), GridItem(.flexible())]
        }
        return [GridItem(.flexible()), GridItem(.flexible())]
    }

    private func sensorMiniView(_ sensor: UnifiedDevice) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: sensor.kind.iconName)
                    .font(.caption2)
                    .foregroundStyle(sensor.kind.themeColor)
                Text(sensor.kind.displayName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            bigNumber(for: sensor)

            if let points = sparklineData[sensor.id], !points.isEmpty {
                SparklineView(points: points, color: sensor.kind.themeColor)
            }
        }
        .padding(8)
        .background(Color(.secondarySystemBackground).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    @ViewBuilder
    private func bigNumber(for sensor: UnifiedDevice) -> some View {
        switch sensor.state {
        case .temperature(let value):
            BigNumberView(
                value: temperatureUnit.format(value).replacingOccurrences(of: "°F", with: "").replacingOccurrences(of: "°C", with: ""),
                unit: temperatureUnit.label,
                color: sensor.kind.themeColor
            )
        case .humidity(let value):
            BigNumberView(value: String(format: "%.0f", value), unit: "%", color: sensor.kind.themeColor)
        case .co2(let value):
            BigNumberView(value: "\(Int(value))", unit: "ppm", color: sensor.kind.themeColor)
        case .battery(let value):
            BigNumberView(value: "\(value)", unit: "%", color: sensor.kind.themeColor)
        default:
            Text(sensor.displayValue)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(sensor.kind.themeColor)
        }
    }
}
