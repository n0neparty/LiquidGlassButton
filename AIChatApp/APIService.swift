import Foundation

@MainActor
final class APIService: Sendable {
    nonisolated(unsafe) static let shared = APIService()
    private init() {}

    func sendMessage(model: AIModel, message: String, chatId: String?) async throws -> ChatResponse {
        guard let url = URL(string: "\(API_BASE)/api/\(model.apiProvider)") else {
            throw URLError(.badURL)
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 30
        var body: [String: Any] = ["message": message, "model": model.apiModel]
        if let chatId { body["chatId"] = chatId }
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode(ChatResponse.self, from: data)
    }

    func clearChat(apiProvider: String, chatId: String) async {
        guard let url = URL(string: "\(API_BASE)/api/\(apiProvider)/chat/\(chatId)") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "DELETE"
        _ = try? await URLSession.shared.data(for: req)
    }
}
