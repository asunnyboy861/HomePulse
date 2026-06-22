import SwiftUI
import Charts

struct SparklineView: View {
    let points: [Double]
    let color: Color
    var showAxis: Bool = false

    var body: some View {
        if points.isEmpty {
            emptyView
        } else {
            chartView
        }
    }

    private var chartView: some View {
        let chartData = points.enumerated().map { ChartDataPoint(index: $0.offset, value: $0.element) }

        return Chart(chartData) { point in
            LineMark(
                x: .value("Index", point.index),
                y: .value("Value", point.value)
            )
            .foregroundStyle(color)
            .interpolationMethod(.catmullRom)
            .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))

            AreaMark(
                x: .value("Index", point.index),
                y: .value("Value", point.value)
            )
            .foregroundStyle(
                .linearGradient(
                    colors: [color.opacity(0.3), color.opacity(0.0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)
        }
        .chartXAxis(showAxis ? .visible : .hidden)
        .chartYAxis(showAxis ? .visible : .hidden)
        .chartLegend(.hidden)
        .frame(height: showAxis ? 200 : 30)
        .accessibilityLabel("Trend chart with \(points.count) data points")
    }

    private var emptyView: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.secondary.opacity(0.1))
            .frame(height: showAxis ? 200 : 30)
            .overlay(
                Image(systemName: "waveform.path.ecg")
                    .foregroundStyle(.secondary.opacity(0.3))
            )
            .accessibilityLabel("No trend data available")
    }
}

private struct ChartDataPoint: Identifiable {
    let id = UUID()
    let index: Int
    let value: Double
}

#Preview {
    VStack(spacing: 20) {
        SparklineView(points: [70, 72, 71, 73, 75, 74, 72, 70, 68, 69], color: .orange)
        SparklineView(points: [45, 46, 48, 50, 52, 51, 49, 47, 45, 44], color: .cyan)
        SparklineView(points: [], color: .gray)
    }
    .padding()
}
