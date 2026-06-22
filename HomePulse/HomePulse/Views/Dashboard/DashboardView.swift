import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel()
    @StateObject private var purchaseManager = PurchaseManager.shared
    @State private var selectedRoom: HomeRoom?
    @State private var showPaywall = false
    @State private var sparklineCache: [String: [Double]] = [:]

    var body: some View {
        NavigationStack {
            ScrollView {
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.isEmpty {
                    emptyStateView
                } else {
                    content
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("HomePulse")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .refreshable {
                await viewModel.refresh()
                updateSparklineCache()
            }
            .task {
                await viewModel.loadInitialData()
                updateSparklineCache()
            }
            .navigationDestination(item: $selectedRoom) { room in
                RoomDetailView(room: room)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
        .environmentObject(settingsViewModel)
        .tint(.accentColor)
    }

    private var content: some View {
        VStack(spacing: 16) {
            summaryHeader

            LazyVStack(spacing: 12) {
                ForEach(viewModel.rooms) { room in
                    RoomCardView(
                        room: room,
                        temperatureUnit: settingsViewModel.temperatureUnit,
                        sparklineData: sparklineCache,
                        onTap: { selectedRoom = room }
                    )
                    .padding(.horizontal)
                }
            }

            QuickScenesView(scenes: viewModel.scenes) { scene in
                Task {
                    await DeviceControlManager.shared.executeScene(scene)
                }
            }

            Spacer(minLength: 20)
        }
        .frame(maxWidth: 720)
        .frame(maxWidth: .infinity)
    }

    private var summaryHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Your Home")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("\(viewModel.totalDevices) devices • \(viewModel.totalLightsOn) lights on")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("Last updated")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(viewModel.lastUpdated.timeAgo)
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }
        .padding(.horizontal)
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading your home...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "house.lodge.fill")
                .font(.system(size: 60))
                .foregroundStyle(.secondary.opacity(0.5))

            VStack(spacing: 8) {
                Text("No Devices Found")
                    .font(.title3)
                    .fontWeight(.semibold)
                Text("Add devices in Apple Home or connect Home Assistant to get started.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)

            NavigationLink(destination: SettingsView()) {
                Text("Open Settings")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .frame(maxWidth: .infinity, minHeight: 400)
        .padding()
    }

    private func updateSparklineCache() {
        for room in viewModel.rooms {
            for sensor in room.sensors {
                let points = SensorHistoryManager.shared.getSparklineData(deviceId: sensor.id).map { $0.value }
                sparklineCache[sensor.id] = points
            }
        }
    }
}

#Preview {
    DashboardView()
}
