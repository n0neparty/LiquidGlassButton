import Foundation
import SwiftUI

let API_BASE = "http://YOUR_SERVER_IP:4000"

// MARK: - Data Models (Sendable для Swift 6)
struct AIProvider: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let icon: String
    let colorHex: String
    let models: [AIModel]

    var color: Color { Color(hex: colorHex) }
}

struct AIModel: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let badge: String?
    let apiProvider: String
    let apiModel: String
}

// Global providers list
let ALL_PROVIDERS: [AIProvider] = [
    AIProvider(id: "grok",     name: "Grok",     icon: "bolt.fill",                   colorHex: "#1D9BF0", models: [
        AIModel(id: "grok-fast",   name: "Grok 4.1 Fast",    badge: "Fast",  apiProvider: "merlin",  apiModel: "grok-4.1-fast"),
        AIModel(id: "grok-mini",   name: "Grok 4.1 Mini",    badge: nil,     apiProvider: "g4f",     apiModel: "grok-4.1-mini:free"),
        AIModel(id: "grok-think",  name: "Grok 3 Thinking",  badge: "Think", apiProvider: "g4f",     apiModel: "grok-3-thinking"),
    ]),
    AIProvider(id: "chatgpt",  name: "ChatGPT",  icon: "sparkles",                    colorHex: "#E8E8E8", models: [
        AIModel(id: "gpt4o-mini",  name: "GPT-4o mini",      badge: "Fast",  apiProvider: "github",  apiModel: "gpt-4o-mini"),
        AIModel(id: "gpt4o",       name: "GPT-4o",           badge: "Pro",   apiProvider: "github",  apiModel: "gpt-4o"),
        AIModel(id: "gpt5-mini",   name: "GPT-5 Mini",       badge: nil,     apiProvider: "merlin",  apiModel: "gpt-5-mini"),
        AIModel(id: "gpt41-nano",  name: "GPT-4.1 Nano",     badge: "Tiny",  apiProvider: "github",  apiModel: "gpt-4.1-nano"),
    ]),
    AIProvider(id: "gemini",   name: "Gemini",   icon: "star.fill",                   colorHex: "#4A90D9", models: [
        AIModel(id: "gem-flash",   name: "Gemini 3 Flash",       badge: "Fast", apiProvider: "gemini",  apiModel: "gemini-3-flash-preview"),
        AIModel(id: "gem-lite",    name: "Gemini 3.1 Flash Lite", badge: nil,   apiProvider: "merlin",  apiModel: "gemini-3.1-flash-lite"),
        AIModel(id: "gem-25",      name: "Gemini 2.5 Flash",     badge: "Pro",  apiProvider: "gemini",  apiModel: "gemini-2.5-flash"),
    ]),
    AIProvider(id: "claude",   name: "Claude",   icon: "wand.and.stars",              colorHex: "#CC8B3C", models: [
        AIModel(id: "haiku",       name: "Claude Haiku 4.5",  badge: "Fast",  apiProvider: "merlin",  apiModel: "claude-haiku-4.5"),
        AIModel(id: "sonnet",      name: "Claude Sonnet 4.5", badge: "Pro",   apiProvider: "g4f",     apiModel: "claude-sonnet-4-5"),
    ]),
    AIProvider(id: "mistral",  name: "Mistral",  icon: "wind",                        colorHex: "#FF6B35", models: [
        AIModel(id: "mis-8b",      name: "Ministral 8B",   badge: "Fast",  apiProvider: "mistral", apiModel: "ministral-8b-latest"),
        AIModel(id: "mis-small",   name: "Mistral Small",  badge: nil,     apiProvider: "mistral", apiModel: "mistral-small-latest"),
        AIModel(id: "mis-nemo",    name: "Mistral Nemo",   badge: nil,     apiProvider: "mistral", apiModel: "open-mistral-nemo"),
    ]),
    AIProvider(id: "deepseek", name: "DeepSeek", icon: "magnifyingglass.circle.fill", colorHex: "#7B68EE", models: [
        AIModel(id: "ds-v3",       name: "DeepSeek V3",  badge: nil,     apiProvider: "g4f",    apiModel: "deepseek-v3"),
        AIModel(id: "ds-r1",       name: "DeepSeek R1",  badge: "Think", apiProvider: "merlin", apiModel: "deepseek-r1"),
    ]),
    AIProvider(id: "llama",    name: "Llama",    icon: "hare.fill",                   colorHex: "#9B59B6", models: [
        AIModel(id: "llama-405b",  name: "Llama 3.1 405B", badge: "Pro",  apiProvider: "github", apiModel: "Meta-Llama-3.1-405B-Instruct"),
        AIModel(id: "llama-8b",    name: "Llama 3.1 8B",   badge: "Fast", apiProvider: "github", apiModel: "Meta-Llama-3.1-8B-Instruct"),
        AIModel(id: "llama-scout", name: "Llama 4 Scout",  badge: nil,    apiProvider: "g4f",    apiModel: "llama-4-scout"),
    ]),
    AIProvider(id: "qwen",     name: "Qwen",     icon: "cpu.fill",                    colorHex: "#E8A838", models: [
        AIModel(id: "qwen-235b",   name: "Qwen 3 235B", badge: "Pro",  apiProvider: "g4f", apiModel: "qwen-3-235b"),
        AIModel(id: "qwen-30b",    name: "Qwen 3 30B",  badge: nil,    apiProvider: "g4f", apiModel: "qwen-3-30b-a3b"),
        AIModel(id: "qwen-14b",    name: "Qwen 3 14B",  badge: "Fast", apiProvider: "g4f", apiModel: "qwen-3-14b"),
    ]),
]

// MARK: - Chat
struct ChatMessage: Identifiable, Sendable {
    let id: UUID
    let role: MessageRole
    let text: String

    init(role: MessageRole, text: String) {
        self.id = UUID()
        self.role = role
        self.text = text
    }
}

enum MessageRole: Sendable { case user, ai, error }

struct ChatResponse: Codable, Sendable {
    let text: String?
    let chatId: String?
    let conversationId: String?
    let error: String?
    var resolvedChatId: String? { chatId ?? conversationId }
}

// MARK: - Color from hex
extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        self.init(
            red:   Double((int >> 16) & 0xFF) / 255,
            green: Double((int >> 8)  & 0xFF) / 255,
            blue:  Double(int         & 0xFF) / 255
        )
    }
}
