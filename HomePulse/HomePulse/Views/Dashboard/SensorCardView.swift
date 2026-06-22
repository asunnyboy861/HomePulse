import SwiftUI

struct SensorCardView: View {
    let device: UnifiedDevice
    let sparklinePoints: [Double]
    let temperatureUnit: TemperatureUnit

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: device.kind.iconName)
                    .foregroundStyle(device.kind.themeColor)
                    .font(.subheadline)
                Text(device.kind.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                ReachabilityDot(isReachable: device.isReachable)
            }

            bigNumber

            if !sparklinePoints.isEmpty {
                SparklineView(points: sparklinePoints, color: device.kind.themeColor)
            }

            Text(device.lastUpdated.timeAgo)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(device.kind.displayName) \(bigNumberText)")
    }

    private var bigNumber: some View {
        switch device.state {
        case .temperature(let value):
            return AnyView(
                BigNumberView(value: temperatureUnit.format(value).replacingOccurrences(of: "°F", with: "").replacingOccurrences(of: "°C", with: ""),
                              unit: temperatureUnit.label, color: device.kind.themeColor)
            )
        case .humidity(let value):
            return AnyView(
                BigNumberView(value: String(format: "%.0f", value), unit: "%", color: device.kind.themeColor)
            )
        case .co2(let value):
            return AnyView(
                BigNumberView(value: "\(Int(value))", unit: "ppm", color: device.kind.themeColor)
            )
        case .battery(let value):
            return AnyView(
                BigNumberView(value: "\(value)", unit: "%", color: device.kind.themeColor)
            )
        default:
            return AnyView(
                Text(device.displayValue)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(device.kind.themeColor)
            )
        }
    }

    private var bigNumberText: String {
        switch device.state {
        case .temperature(let value): return temperatureUnit.format(value)
        case .humidity(let value): return String(format: "%.0f%%", value)
        case .co2(let value): return "\(Int(value)) ppm"
        case .battery(let value): return "\(value)%"
        default: return device.displayValue
        }
    }
}
