import Foundation

class APIService {
    static let shared = APIService()

    func fetchModels(provider: String) async throws -> [AIModel] {
        let url = URL(string: "\(API_BASE)/api/\(provider)/models")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(ModelsResponse.self, from: data)
        return response.models
    }

    func sendMessage(
        provider: String,
        model: String,
        message: String,
        chatId: String?
    ) async throws -> ChatResponse {
        let url = URL(string: "\(API_BASE)/api/\(provider)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = ["message": message, "model": model]
        if let chatId { body["chatId"] = chatId }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(ChatResponse.self, from: data)
    }

    func clearChat(provider: String, chatId: String) async {
        guard let url = URL(string: "\(API_BASE)/api/\(provider)/chat/\(chatId)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        _ = try? await URLSession.shared.data(for: request)
    }
}
