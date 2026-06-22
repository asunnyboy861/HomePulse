import SwiftUI

struct DeviceCardView: View {
    let device: UnifiedDevice
    let isPro: Bool
    let onToggle: () -> Void
    let onBrightnessChange: (Int) -> Void
    let onTemperatureChange: (Double) -> Void
    let onProTapped: () -> Void

    @State private var brightness: Double = 50
    @State private var targetTemp: Double = 70

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: device.kind.iconName)
                    .foregroundStyle(device.kind.themeColor)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text(device.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(device.displayValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                ReachabilityDot(isReachable: device.isReachable)
            }

            switch device.kind {
            case .light:
                lightControls
            case .switchDevice:
                switchControls
            case .thermostat:
                thermostatControls
            case .lock:
                lockControls
            default:
                EmptyView()
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onAppear { initializeValues() }
    }

    private var lightControls: some View {
        VStack(spacing: 10) {
            HStack {
                Toggle("", isOn: powerStateBinding)
                    .labelsHidden()
                    .tint(device.kind.themeColor)
                Spacer()
                Text(device.displayValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if case .brightness(let current) = device.state, current > 0 {
                HStack {
                    Image(systemName: "sun.min")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Slider(value: $brightness, in: 0...100, onEditingChanged: { editing in
                        if !editing {
                            onBrightnessChange(Int(brightness))
                        }
                    })
                    .tint(device.kind.themeColor)
                    Image(systemName: "sun.max.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var switchControls: some View {
        HStack {
            Spacer()
            Toggle("", isOn: powerStateBinding)
                .labelsHidden()
                .tint(device.kind.themeColor)
        }
    }

    private var thermostatControls: some View {
        Group {
            if isPro {
                VStack(spacing: 10) {
                    HStack {
                        Button(action: { adjustTemp(delta: -1) }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        Spacer()
                        Text(String(format: "%.0f°", targetTemp))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(device.kind.themeColor)
                            .contentTransition(.numericText())
                        Spacer()
                        Button(action: { adjustTemp(delta: 1) }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    Slider(value: $targetTemp, in: 50...85, onEditingChanged: { editing in
                        if !editing {
                            onTemperatureChange(targetTemp)
                        }
                    })
                    .tint(device.kind.themeColor)
                }
            } else {
                Button(action: onProTapped) {
                    HStack {
                        Image(systemName: "lock.fill")
                        Text("Unlock with Pro")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.accentColor.opacity(0.1))
                    .foregroundStyle(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var lockControls: some View {
        HStack {
            Spacer()
            Image(systemName: lockIcon)
                .font(.title2)
                .foregroundStyle(device.kind.themeColor)
        }
    }

    private var lockIcon: String {
        if case .locked(let locked) = device.state {
            return locked ? "lock.fill" : "lock.open.fill"
        }
        return "lock.fill"
    }

    private var powerStateBinding: Binding<Bool> {
        Binding(
            get: {
                if case .power(let on) = device.state { return on }
                if case .brightness(let b) = device.state { return b > 0 }
                return false
            },
            set: { _ in onToggle() }
        )
    }

    private func initializeValues() {
        if case .brightness(let b) = device.state {
            brightness = Double(b)
        }
        if case .temperature(let t) = device.state {
            targetTemp = t
        }
    }

    private func adjustTemp(delta: Double) {
        targetTemp = max(50, min(85, targetTemp + delta))
        onTemperatureChange(targetTemp)
    }
}
