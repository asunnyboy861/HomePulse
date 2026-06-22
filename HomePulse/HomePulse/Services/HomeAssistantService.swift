import Foundation

actor HomeAssistantService {
    static let shared = HomeAssistantService()

    private(set) var rooms: [HomeRoom] = []
    private(set) var scenes: [HomeScene] = []
    private(set) var entities: [HAEntity] = []

    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession
    private var serverURL: URL?
    private var token: String?
    private var isConnected = false
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5

    private var stateChangeContinuation: AsyncStream<HAEntity>.Continuation?

    init() {
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        urlSession = URLSession(configuration: config)
    }

    func configure(url: URL, token: String) {
        self.serverURL = url
        self.token = token
    }

    func connect() async throws {
        guard let serverURL, let token else {
            throw HAError.notConfigured
        }

        var wsComponents = URLComponents(url: serverURL, resolvingAgainstBaseURL: false)
        if wsComponents?.scheme == "https" {
            wsComponents?.scheme = "wss"
        } else if wsComponents?.scheme == "http" {
            wsComponents?.scheme = "ws"
        }
        wsComponents?.path = "/api/websocket"

        guard let wsURL = wsComponents?.url else {
            throw HAError.invalidURL
        }

        let task = urlSession.webSocketTask(with: wsURL)
        webSocketTask = task
        task.resume()

        try await authenticate(token: token)
        isConnected = true
        reconnectAttempts = 0

        try await subscribeToStateChanges()
        try await fetchAllStates()

        Task { await listenForMessages() }
        Task { await startReconnectMonitor() }
    }

    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        isConnected = false
    }

    private func authenticate(token: String) async throws {
        guard let task = webSocketTask else { throw HAError.notConnected }

        let message = try await task.receive()
        switch message {
        case .string(let text):
            guard let data = text.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  json["type"] as? String == "auth_required"
            else { throw HAError.authFailed }

            let authMessage: [String: Any] = ["type": "auth", "access_token": token]
            let authData = try JSONSerialization.data(withJSONObject: authMessage)
            task.send(.string(String(data: authData, encoding: .utf8) ?? "")) { _ in }

            let response = try await task.receive()
            if case .string(let responseText) = response,
               let responseData = responseText.data(using: .utf8),
               let responseJson = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
               responseJson["type"] as? String == "auth_ok"
            {
                return
            }
            throw HAError.authFailed
        case .data:
            throw HAError.authFailed
        @unknown default:
            throw HAError.authFailed
        }
    }

    private func subscribeToStateChanges() async throws {
        guard let task = webSocketTask else { throw HAError.notConnected }

        let message: [String: Any] = [
            "type": "subscribe_events",
            "event_type": "state_changed",
            "id": 1
        ]
        let data = try JSONSerialization.data(withJSONObject: message)
        task.send(.string(String(data: data, encoding: .utf8) ?? "")) { _ in }
    }

    private func fetchAllStates() async throws {
        guard let serverURL, let token else { throw HAError.notConfigured }

        var statesURL = serverURL
        statesURL.append(path: "/api/states")

        var request = URLRequest(url: statesURL)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200
        else { throw HAError.requestFailed }

        let decoded = try JSONDecoder().decode([HAEntity].self, from: data)
        entities = decoded
        buildRoomsAndScenes()
    }

    private func buildRoomsAndScenes() {
        var roomDict: [String: [UnifiedDevice]] = [:]
        var newScenes: [HomeScene] = []

        for entity in entities {
            if entity.entityId.hasPrefix("scene.") {
                newScenes.append(HomeScene(
                    id: entity.entityId,
                    name: entity.attributes.friendlyName ?? entity.entityId.replacingOccurrences(of: "scene.", with: ""),
                    platform: .homeAssistant,
                    iconName: sceneIcon(for: entity.entityId)
                ))
                continue
            }

            guard let device = mapEntity(entity) else { continue }
            let roomName = entity.attributes.areaName ?? "Default"
            roomDict[roomName, default: []].append(device)
        }

        rooms = roomDict.map { HomeRoom(id: $0.key, name: $0.key, devices: $0.value) }
        scenes = newScenes
    }

    private func mapEntity(_ entity: HAEntity) -> UnifiedDevice? {
        let entityId = entity.entityId
        let state = entity.state
        let friendlyName = entity.attributes.friendlyName ?? entityId

        if entityId.hasPrefix("sensor.") {
            if let unit = entity.attributes.unitOfMeasurement?.lowercased() {
                if unit.contains("f") || unit.contains("c") || entityId.contains("temp") {
                    if let value = Double(state) {
                        return UnifiedDevice(
                            id: entityId, name: friendlyName, roomName: entity.attributes.areaName ?? "Default",
                            platform: .homeAssistant, kind: .temperatureSensor,
                            state: .temperature(value), isReachable: true, lastUpdated: Date()
                        )
                    }
                }
                if unit.contains("%") || entityId.contains("humid") {
                    if let value = Double(state) {
                        return UnifiedDevice(
                            id: entityId, name: friendlyName, roomName: entity.attributes.areaName ?? "Default",
                            platform: .homeAssistant, kind: .humiditySensor,
                            state: .humidity(value), isReachable: true, lastUpdated: Date()
                        )
                    }
                }
                if entityId.contains("co2") || entityId.contains("carbon_dioxide") {
                    if let value = Double(state) {
                        return UnifiedDevice(
                            id: entityId, name: friendlyName, roomName: entity.attributes.areaName ?? "Default",
                            platform: .homeAssistant, kind: .co2Sensor,
                            state: .co2(value), isReachable: true, lastUpdated: Date()
                        )
                    }
                }
                if entityId.contains("battery") {
                    if let value = Double(state) {
                        return UnifiedDevice(
                            id: entityId, name: friendlyName, roomName: entity.attributes.areaName ?? "Default",
                            platform: .homeAssistant, kind: .battery,
                            state: .battery(Int(value)), isReachable: true, lastUpdated: Date()
                        )
                    }
                }
            }
        }

        if entityId.hasPrefix("light.") {
            let on = state == "on"
            let brightness: Int? = {
                if let b = entity.attributes.brightness {
                    return Int(Double(b) / 255.0 * 100)
                }
                return nil
            }()
            return UnifiedDevice(
                id: entityId, name: friendlyName, roomName: entity.attributes.areaName ?? "Default",
                platform: .homeAssistant, kind: .light,
                state: brightness.map { .brightness($0) } ?? .power(on),
                isReachable: true, lastUpdated: Date()
            )
        }

        if entityId.hasPrefix("switch.") {
            let on = state == "on"
            return UnifiedDevice(
                id: entityId, name: friendlyName, roomName: entity.attributes.areaName ?? "Default",
                platform: .homeAssistant, kind: .switchDevice,
                state: .power(on), isReachable: true, lastUpdated: Date()
            )
        }

        if entityId.hasPrefix("lock.") {
            let locked = state == "locked"
            return UnifiedDevice(
                id: entityId, name: friendlyName, roomName: entity.attributes.areaName ?? "Default",
                platform: .homeAssistant, kind: .lock,
                state: .locked(locked), isReachable: true, lastUpdated: Date()
            )
        }

        if entityId.hasPrefix("climate.") {
            if let temp = entity.attributes.temperature, let value = Double(String(temp)) {
                return UnifiedDevice(
                    id: entityId, name: friendlyName, roomName: entity.attributes.areaName ?? "Default",
                    platform: .homeAssistant, kind: .thermostat,
                    state: .temperature(value), isReachable: true, lastUpdated: Date()
                )
            }
        }

        return nil
    }

    private func sceneIcon(for entityId: String) -> String {
        let lower = entityId.lowercased()
        if lower.contains("movie") || lower.contains("tv") { return "film.fill" }
        if lower.contains("night") || lower.contains("sleep") { return "moon.stars.fill" }
        if lower.contains("day") || lower.contains("morning") { return "sun.max.fill" }
        if lower.contains("home") || lower.contains("arrive") { return "house.fill" }
        if lower.contains("away") || lower.contains("leave") { return "figure.walk" }
        return "sparkles"
    }

    private func listenForMessages() async {
        guard let task = webSocketTask else { return }

        while isConnected {
            do {
                let message = try await task.receive()
                switch message {
                case .string(let text):
                    await handleMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        await handleMessage(text)
                    }
                @unknown default:
                    break
                }
            } catch {
                isConnected = false
                break
            }
        }
    }

    private func handleMessage(_ text: String) async {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let eventType = json["type"] as? String
        else { return }

        if eventType == "event",
           let eventData = json["event"] as? [String: Any],
           let newState = eventData["new_state"] as? [String: Any] {
            if let entityData = try? JSONSerialization.data(withJSONObject: newState),
               let entity = try? JSONDecoder().decode(HAEntity.self, from: entityData) {
                await updateEntity(entity)
            }
        }
    }

    private func updateEntity(_ entity: HAEntity) async {
        if let index = entities.firstIndex(where: { $0.entityId == entity.entityId }) {
            entities[index] = entity
        } else {
            entities.append(entity)
        }
        buildRoomsAndScenes()
    }

    private func startReconnectMonitor() async {
        while !isConnected && reconnectAttempts < maxReconnectAttempts {
            reconnectAttempts += 1
            let delay = min(5.0 * Double(reconnectAttempts), 30.0)
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            if !isConnected {
                try? await connect()
            }
        }
    }

    func callService(domain: String, service: String, entityId: String) async throws {
        guard let serverURL, let token else { throw HAError.notConfigured }

        var serviceURL = serverURL
        serviceURL.append(path: "/api/services/\(domain)/\(service)")

        var request = URLRequest(url: serviceURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["entity_id": entityId]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        _ = try await urlSession.data(for: request)
    }

    func toggleDevice(_ deviceId: String) async throws {
        if deviceId.hasPrefix("light.") {
            try await callService(domain: "light", service: "toggle", entityId: deviceId)
        } else if deviceId.hasPrefix("switch.") {
            try await callService(domain: "switch", service: "toggle", entityId: deviceId)
        }
    }

    func setBrightness(_ value: Int, for deviceId: String) async throws {
        guard deviceId.hasPrefix("light.") else { return }
        let brightness = Int(Double(value) / 100.0 * 255.0)

        guard let serverURL, let token else { throw HAError.notConfigured }

        var serviceURL = serverURL
        serviceURL.append(path: "/api/services/light/turn_on")

        var request = URLRequest(url: serviceURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "entity_id": deviceId,
            "brightness": brightness
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        _ = try await urlSession.data(for: request)
    }

    func setTargetTemperature(_ value: Double, for deviceId: String) async throws {
        guard deviceId.hasPrefix("climate.") else { return }

        guard let serverURL, let token else { throw HAError.notConfigured }

        var serviceURL = serverURL
        serviceURL.append(path: "/api/services/climate/set_temperature")

        var request = URLRequest(url: serviceURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "entity_id": deviceId,
            "temperature": value
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        _ = try await urlSession.data(for: request)
    }

    func executeScene(_ sceneId: String) async throws {
        try await callService(domain: "scene", service: "turn_on", entityId: sceneId)
    }

    func getSnapshot() async -> [HomeRoom] {
        rooms
    }
}

enum HAError: Error, LocalizedError {
    case notConfigured
    case invalidURL
    case notConnected
    case authFailed
    case requestFailed

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "Home Assistant is not configured"
        case .invalidURL: return "Invalid server URL"
        case .notConnected: return "Not connected to Home Assistant"
        case .authFailed: return "Authentication failed. Check your token."
        case .requestFailed: return "Request to Home Assistant failed"
        }
    }
}

struct HAEntity: Codable, Identifiable {
    let entityId: String
    let state: String
    let attributes: HAAttributes
    let lastChanged: Date?

    var id: String { entityId }

    enum CodingKeys: String, CodingKey {
        case entityId = "entity_id"
        case state
        case attributes
        case lastChanged = "last_changed"
    }
}

struct HAAttributes: Codable {
    let friendlyName: String?
    let unitOfMeasurement: String?
    let areaName: String?
    let brightness: Int?
    let temperature: Double?

    enum CodingKeys: String, CodingKey {
        case friendlyName = "friendly_name"
        case unitOfMeasurement = "unit_of_measurement"
        case areaName = "area_id"
        case brightness
        case temperature
    }
}
