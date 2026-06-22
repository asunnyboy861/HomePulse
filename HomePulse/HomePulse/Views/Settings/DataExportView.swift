import SwiftUI

struct DataExportView: View {
    @StateObject private var dashboardVM = DashboardViewModel()
    @StateObject private var purchaseManager = PurchaseManager.shared
    @State private var selectedSensor: UnifiedDevice?
    @State private var selectedDays: Int = 30
    @State private var exportURL: URL?
    @State private var showShareSheet = false

    private let dayOptions = [7, 30, 90]

    var body: some View {
        Form {
            if !purchaseManager.isPro {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "lock.fill")
                            .font(.title)
                            .foregroundStyle(.secondary)
                        Text("Pro Feature")
                            .font(.headline)
                        Text("Upgrade to Pro to export sensor history as CSV files.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        NavigationLink("Upgrade to Pro") {
                            PaywallView()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
            } else {
                Section {
                    let sensors = dashboardVM.rooms.flatMap { $0.sensors }
                    if sensors.isEmpty {
                        Text("No sensors available.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Sensor", selection: $selectedSensor) {
                            Text("Select a sensor").tag(nil as UnifiedDevice?)
                            ForEach(sensors) { sensor in
                                Text(sensor.name).tag(sensor as UnifiedDevice?)
                            }
                        }
                    }
                } header: {
                    Text("Select Sensor")
                }

                Section {
                    Picker("Date Range", selection: $selectedDays) {
                        ForEach(dayOptions, id: \.self) { days in
                            Text("\(days) days").tag(days)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Date Range")
                }

                Section {
                    Button(action: exportCSV) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export CSV")
                        }
                    }
                    .disabled(selectedSensor == nil)
                }
            }
        }
        .navigationTitle("Data Export")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await dashboardVM.loadInitialData()
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
        }
    }

    private func exportCSV() {
        guard let sensor = selectedSensor else { return }
        if let url = DataExportService.shared.exportSensorData(deviceId: sensor.id, deviceName: sensor.name, days: selectedDays) {
            exportURL = url
            showShareSheet = true
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
