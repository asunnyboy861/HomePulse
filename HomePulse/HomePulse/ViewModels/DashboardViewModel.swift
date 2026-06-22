import Foundation
import SwiftUI
import Combine

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var rooms: [HomeRoom] = []
    @Published var scenes: [HomeScene] = []
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var errorMessage: String?
    @Published var lastUpdated: Date = Date()

    private let homeKitService = HomeKitService.shared
    private let haService = HomeAssistantService.shared
    private let historyManager = SensorHistoryManager.shared
    private let notificationService = NotificationService.shared
    private var refreshTimer: Timer?

    init() {
        startAutoRefresh()
    }

    deinit {
        refreshTimer?.invalidate()
    }

    func loadInitialData() async {
        isLoading = true
        errorMessage = nil

        let platform = UserDefaults.standard.string(forKey: "platformChoice")

        if platform == "homekit" || platform == nil {
            homeKitService.start()
            await waitForHomeKit()
            rooms = homeKitService.rooms
            scenes = homeKitService.scenes
        }

        if platform == "homeAssistant" {
            await loadHAData()
        }

        await sampleSensors()
        lastUpdated = Date()
        isLoading = false
    }

    private func waitForHomeKit() async {
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        rooms = homeKitService.rooms
        scenes = homeKitService.scenes
    }

    private func loadHAData() async {
        guard let urlStr = UserDefaults.standard.string(forKey: "haURL"),
              let token = UserDefaults.standard.string(forKey: "haToken"),
              let url = URL(string: urlStr)
        else { return }

        await haService.configure(url: url, token: token)
        do {
            try await haService.connect()
            rooms = await haService.getSnapshot()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refresh() async {
        isRefreshing = true
        await loadInitialData()
        isRefreshing = false
    }

    func sampleSensors() async {
        let allDevices = rooms.flatMap { $0.devices }
        historyManager.sampleAllSensors(devices: allDevices)

        for device in allDevices {
            if let value = device.numericValue {
                notificationService.checkThreshold(
                    deviceId: device.id,
                    deviceName: device.name,
                    value: value
                )
            }
        }
    }

    private func startAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.sampleSensors()
            }
        }
    }

    var totalLightsOn: Int {
        rooms.reduce(0) { $0 + $1.lightsOnCount }
    }

    var totalSensors: Int {
        rooms.reduce(0) { $0 + $1.sensors.count }
    }

    var totalDevices: Int {
        rooms.reduce(0) { $0 + $1.devices.count }
    }

    var isEmpty: Bool {
        rooms.isEmpty || rooms.allSatisfy { $0.devices.isEmpty }
    }
}
