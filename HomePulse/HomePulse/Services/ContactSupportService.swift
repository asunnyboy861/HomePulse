import Foundation
import Combine

struct FeedbackRequest: Codable {
    let name: String
    let email: String
    let subject: String
    let message: String
    let app_name: String
}

struct FeedbackResponse: Codable {
    let success: Bool
    let id: Int?
    let error: String?
}

struct FeedbackResult {
    let success: Bool
    let id: Int?
    let errorMessage: String?
}

final class ContactSupportService: ObservableObject {
    static let shared = ContactSupportService()

    private let backendURL = URL(string: "https://feedback-board.iocompile67692.workers.dev")!

    func submitFeedback(name: String, email: String, subject: String, message: String) async -> FeedbackResult {
        let request = FeedbackRequest(
            name: name,
            email: email,
            subject: subject,
            message: message,
            app_name: "HomePulse"
        )

        var urlRequest = URLRequest(url: backendURL.appending(path: "/api/feedback"))
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = 15

        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                return FeedbackResult(success: false, id: nil, errorMessage: "Invalid response from server")
            }

            if httpResponse.statusCode == 200 {
                if let decoded = try? JSONDecoder().decode(FeedbackResponse.self, from: data),
                   decoded.success {
                    return FeedbackResult(success: true, id: decoded.id ?? 0, errorMessage: nil)
                }
                return FeedbackResult(success: true, id: 0, errorMessage: nil)
            } else {
                if let decoded = try? JSONDecoder().decode(FeedbackResponse.self, from: data),
                   let error = decoded.error {
                    return FeedbackResult(success: false, id: nil, errorMessage: error)
                }
                return FeedbackResult(success: false, id: nil, errorMessage: "Failed to submit feedback (status \(httpResponse.statusCode))")
            }
        } catch let urlError as URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                return FeedbackResult(success: false, id: nil, errorMessage: "No internet connection. Please check your network and try again.")
            case .timedOut:
                return FeedbackResult(success: false, id: nil, errorMessage: "Request timed out. Please try again.")
            default:
                return FeedbackResult(success: false, id: nil, errorMessage: "Network error: \(urlError.localizedDescription)")
            }
        } catch {
            return FeedbackResult(success: false, id: nil, errorMessage: "Failed to submit feedback: \(error.localizedDescription)")
        }
    }
}
