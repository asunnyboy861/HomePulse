import Foundation
import UIKit
import Combine

@MainActor
final class DataExportService: ObservableObject {
    static let shared = DataExportService()

    func exportSensorData(deviceId: String, deviceName: String, days: Int) -> URL? {
        guard let csv = SensorHistoryManager.shared.exportCSV(deviceId: deviceId, days: days) else {
            return nil
        }

        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "\(deviceName)_\(days)days_\(Int(Date().timeIntervalSince1970)).csv"
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            return nil
        }
    }

    func shareCSV(url: URL) {
        let activityVC = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
}
