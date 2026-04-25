import Foundation
import UIKit

final class APIService: Sendable {
    static let shared = APIService()
    private init() {}

    func sendMessage(model: AIModel, message: String, chatId: String?, image: UIImage? = nil) async throws -> ChatResponse {
        guard let url = URL(string: "\(API_BASE)/api/\(model.apiProvider)") else {
            throw URLError(.badURL)
        }
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.timeoutInterval = 60
        
        var body: [String: Any] = ["message": message, "model": model.apiModel]
        if let chatId { body["chatId"] = chatId }
        if let conversationId = chatId { body["conversationId"] = conversationId }
        
        // If image is provided, convert to base64
        if let image = image {
            if let imageData = image.jpegData(compressionQuality: 0.8) {
                let base64String = imageData.base64EncodedString()
                body["image"] = "data:image/jpeg;base64,\(base64String)"
            }
        }
        
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
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
