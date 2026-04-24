import Foundation

// MARK: - API Base
let API_BASE = "https://your-server.railway.app" // замени на свой URL

// MARK: - Provider
struct Provider: Identifiable, Hashable {
    let id: String
    let name: String
    let color: String
}

let PROVIDERS: [Provider] = [
    Provider(id: "merlin",  name: "Merlin",        color: "#6366f1"),
    Provider(id: "monica",  name: "Monica",        color: "#ec4899"),
    Provider(id: "github",  name: "GitHub Models", color: "#22c55e"),
    Provider(id: "mistral", name: "Mistral",       color: "#f97316"),
    Provider(id: "gemini",  name: "Gemini",        color: "#3b82f6"),
    Provider(id: "g4f",     name: "GPT4Free",      color: "#a855f7"),
]

// MARK: - Model
struct AIModel: Identifiable, Codable, Hashable {
    let id: String
    let name: String?
    let cost: Int?

    var displayName: String { name ?? id }
}

struct ModelsResponse: Codable {
    let models: [AIModel]
}

// MARK: - Chat
struct ChatMessage: Identifiable {
    let id = UUID()
    let role: MessageRole
    let text: String
    let timestamp = Date()
}

enum MessageRole {
    case user, ai, error
}

struct ChatResponse: Codable {
    let text: String
    let chatId: String?
    let conversationId: String?
    let error: String?

    var resolvedChatId: String? { chatId ?? conversationId }
}
