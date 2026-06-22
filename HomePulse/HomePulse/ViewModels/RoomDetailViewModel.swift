import Foundation
import SwiftUI
import Combine

@MainActor
final class RoomDetailViewModel: ObservableObject {
    @Published var room: HomeRoom
    @Published var selectedTimeRange: TimeRange = .day
    @Published var chartData: [ReadingPoint] = []
    @Published var stats: (min: Double?, max: Double?, avg: Double?) = (nil, nil, nil)

    let historyManager = SensorHistoryManager.shared

    init(room: HomeRoom) {
        self.room = room
    }

    func loadChartData(for deviceId: String) {
        let days = selectedTimeRange.rawValue
        chartData = historyManager.getHistoryData(deviceId: deviceId, days: days)
        stats = historyManager.getStats(deviceId: deviceId, days: days)
    }

    func updateRoom(_ room: HomeRoom) {
        self.room = room
    }
}

enum TimeRange: Int, CaseIterable {
    case day = 1
    case week = 7
    case month = 30

    var label: String {
        switch self {
        case .day: return "24h"
        case .week: return "7d"
        case .month: return "30d"
        }
    }
}
