import SwiftUI
import Charts

struct RoomDetailView: View {
    let room: HomeRoom

    @StateObject private var viewModel: RoomDetailViewModel
    @StateObject private var settingsViewModel = SettingsViewModel()
    @StateObject private var purchaseManager = PurchaseManager.shared
    @State private var showPaywall = false
    @State private var selectedSensor: UnifiedDevice?

    init(room: HomeRoom) {
        self.room = room
        _viewModel = StateObject(wrappedValue: RoomDetailViewModel(room: room))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                sensorsSection
                devicesSection
            }
            .padding()
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(room.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    private var sensorsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !room.sensors.isEmpty {
                Text("Sensors")
                    .font(.headline)

                ForEach(room.sensors) { sensor in
                    sensorDetailCard(sensor)
                }
            }
        }
    }

    private func sensorDetailCard(_ sensor: UnifiedDevice) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: sensor.kind.iconName)
                    .foregroundStyle(sensor.kind.themeColor)
                Text(sensor.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                ReachabilityDot(isReachable: sensor.isReachable)
            }

            bigNumber(for: sensor)

            if purchaseManager.isPro {
                timeRangePicker(for: sensor)
                chartView(for: sensor)
                statsRow(for: sensor)
            } else {
                lockedChartView
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    @ViewBuilder
    private func bigNumber(for sensor: UnifiedDevice) -> some View {
        switch sensor.state {
        case .temperature(let value):
            BigNumberView(
                value: settingsViewModel.temperatureUnit.format(value).replacingOccurrences(of: "°F", with: "").replacingOccurrences(of: "°C", with: ""),
                unit: settingsViewModel.temperatureUnit.label,
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
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(sensor.kind.themeColor)
        }
    }

    private func timeRangePicker(for sensor: UnifiedDevice) -> some View {
        Picker("Time Range", selection: $viewModel.selectedTimeRange) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Text(range.label).tag(range)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: viewModel.selectedTimeRange) {
            viewModel.loadChartData(for: sensor.id)
        }
        .onAppear {
            viewModel.loadChartData(for: sensor.id)
        }
    }

    private func chartView(for sensor: UnifiedDevice) -> some View {
        Group {
            if viewModel.chartData.isEmpty {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.1))
                    .frame(height: 200)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.title)
                                .foregroundStyle(.secondary.opacity(0.4))
                            Text("No history data yet")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    )
            } else {
                let chartData = viewModel.chartData.enumerated().map { ChartDataPoint(date: $0.element.timestamp, value: $0.element.value) }
                Chart(chartData) { point in
                    LineMark(
                        x: .value("Time", point.date),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(sensor.kind.themeColor)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))

                    AreaMark(
                        x: .value("Time", point.date),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(.linearGradient(
                        colors: [sensor.kind.themeColor.opacity(0.3), sensor.kind.themeColor.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .interpolationMethod(.catmullRom)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: viewModel.selectedTimeRange == .day ? .hour : .day)) { value in
                        AxisGridLine()
                        AxisValueLabel(format: viewModel.selectedTimeRange == .day ? .dateTime.hour() : .dateTime.day().month())
                    }
                }
                .frame(height: 200)
            }
        }
    }

    private func statsRow(for sensor: UnifiedDevice) -> some View {
        HStack {
            statItem(title: "Min", value: viewModel.stats.min, color: sensor.kind.themeColor)
            Divider().frame(height: 30)
            statItem(title: "Avg", value: viewModel.stats.avg, color: sensor.kind.themeColor)
            Divider().frame(height: 30)
            statItem(title: "Max", value: viewModel.stats.max, color: sensor.kind.themeColor)
        }
        .padding(.top, 4)
    }

    private func statItem(title: String, value: Double?, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value.map { String(format: "%.1f", $0) } ?? "—")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
    }

    private var lockedChartView: some View {
        Button(action: { showPaywall = true }) {
            VStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("Unlock Historical Charts with Pro")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.accentColor)
                Text("7-day and 30-day trends, min/max/avg stats")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(Color.accentColor.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private var devicesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !room.controllables.isEmpty {
                Text("Devices")
                    .font(.headline)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(room.controllables) { device in
                        DeviceCardView(
                            device: device,
                            isPro: purchaseManager.isPro,
                            onToggle: {
                                Task { await DeviceControlManager.shared.toggle(device: device) }
                            },
                            onBrightnessChange: { value in
                                Task { await DeviceControlManager.shared.setBrightness(value, for: device) }
                            },
                            onTemperatureChange: { value in
                                Task { await DeviceControlManager.shared.setTargetTemperature(value, for: device) }
                            },
                            onProTapped: { showPaywall = true }
                        )
                    }
                }
            }
        }
    }
}

private struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}
