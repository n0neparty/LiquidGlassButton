import Foundation
import SwiftUI
import UIKit

let API_BASE = "http://144.31.224.7:4000"

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
        AIModel(id: "grok-4",      name: "Grok 4",           badge: nil,     apiProvider: "g4f",     apiModel: "grok"),
    ]),
    AIProvider(id: "chatgpt",  name: "ChatGPT",  icon: "sparkles",                    colorHex: "#10A37F", models: [
        AIModel(id: "gpt4o-mini",  name: "GPT-4o mini",      badge: "Fast",  apiProvider: "github",  apiModel: "gpt-4o-mini"),
        AIModel(id: "gpt4o",       name: "GPT-4o",           badge: "Pro",   apiProvider: "github",  apiModel: "gpt-4o"),
        AIModel(id: "gpt5-mini",   name: "GPT-5 Mini",       badge: nil,     apiProvider: "merlin",  apiModel: "gpt-5-mini"),
        AIModel(id: "gpt54-nano",  name: "GPT-5.4 Nano",     badge: "Tiny",  apiProvider: "monica",  apiModel: "gpt-5.4-nano"),
        AIModel(id: "gpt54-mini",  name: "GPT-5.4 Mini",     badge: nil,     apiProvider: "monica",  apiModel: "gpt-5.4-mini"),
        AIModel(id: "gpt41-nano",  name: "GPT-4.1 Nano",     badge: "Tiny",  apiProvider: "monica",  apiModel: "gpt-4.1-nano"),
        AIModel(id: "gpt54",       name: "GPT-5.4",          badge: "Pro",   apiProvider: "merlin",  apiModel: "gpt-5.4"),
        AIModel(id: "gpt52",       name: "GPT-5.2",          badge: "Pro",   apiProvider: "merlin",  apiModel: "gpt-5.2"),
        AIModel(id: "gpt51",       name: "GPT-5.1",          badge: nil,     apiProvider: "merlin",  apiModel: "gpt-5.1"),
        AIModel(id: "gpt-oss",     name: "GPT OSS 120B",     badge: nil,     apiProvider: "merlin",  apiModel: "gpt-oss-120b"),
        AIModel(id: "openai-lg",   name: "OpenAI Large",     badge: nil,     apiProvider: "g4f",     apiModel: "openai-large"),
    ]),
    AIProvider(id: "gemini",   name: "Gemini",   icon: "star.fill",                   colorHex: "#4285F4", models: [
        AIModel(id: "gem3-flash",      name: "Gemini 3 Flash",           badge: "Fast", apiProvider: "gemini",  apiModel: "gemini-3-flash-preview"),
        AIModel(id: "gem31-flash-lite", name: "Gemini 3.1 Flash Lite",   badge: "Lite", apiProvider: "gemini",  apiModel: "gemini-3.1-flash-lite-preview"),
        AIModel(id: "gem31-pro",       name: "Gemini 3.1 Pro",           badge: "Pro",  apiProvider: "merlin",  apiModel: "gemini-3.1-pro"),
        AIModel(id: "gem30-pro",       name: "Gemini 3.0 Pro",           badge: "Pro",  apiProvider: "merlin",  apiModel: "gemini-3.0-pro"),
        AIModel(id: "gem25-flash",     name: "Gemini 2.5 Flash",         badge: nil,    apiProvider: "gemini",  apiModel: "gemini-2.5-flash"),
        AIModel(id: "gem25-lite",      name: "Gemini 2.5 Flash Lite",    badge: "Lite", apiProvider: "gemini",  apiModel: "gemini-2.5-flash-lite"),
        AIModel(id: "gem-flash-latest", name: "Gemini Flash Latest",     badge: nil,    apiProvider: "gemini",  apiModel: "gemini-flash-latest"),
        AIModel(id: "gem-lite-latest",  name: "Gemini Flash Lite Latest", badge: "Lite", apiProvider: "gemini",  apiModel: "gemini-flash-lite-latest"),
        AIModel(id: "gem-fast",        name: "Gemini Fast",              badge: "Fast", apiProvider: "g4f",     apiModel: "gemini-fast"),
        AIModel(id: "gem-search",      name: "Gemini Search",            badge: nil,    apiProvider: "g4f",     apiModel: "gemini-search"),
    ]),
    AIProvider(id: "claude",   name: "Claude",   icon: "wand.and.stars",              colorHex: "#CC8B65", models: [
        AIModel(id: "haiku45",     name: "Claude Haiku 4.5",  badge: "Fast",  apiProvider: "merlin",  apiModel: "claude-haiku-4.5"),
        AIModel(id: "sonnet45",    name: "Claude Sonnet 4.5", badge: "Pro",   apiProvider: "g4f",     apiModel: "claude45sonnet"),
        AIModel(id: "claude-fast", name: "Claude Fast",       badge: "Fast",  apiProvider: "g4f",     apiModel: "claude-fast"),
    ]),
    AIProvider(id: "mistral",  name: "Mistral",  icon: "wind",                        colorHex: "#FF6B35", models: [
        AIModel(id: "mis-small",   name: "Mistral Small",  badge: nil,     apiProvider: "mistral", apiModel: "mistral-small-latest"),
        AIModel(id: "mis-large",   name: "Mistral Large",  badge: "Pro",   apiProvider: "mistral", apiModel: "mistral-large-latest"),
        AIModel(id: "mis-nemo",    name: "Mistral Nemo",   badge: nil,     apiProvider: "mistral", apiModel: "open-mistral-nemo"),
        AIModel(id: "codestral",   name: "Codestral",      badge: "Code",  apiProvider: "mistral", apiModel: "codestral-latest"),
        AIModel(id: "mis-3b",      name: "Ministral 3B",   badge: "Tiny",  apiProvider: "mistral", apiModel: "ministral-3b-latest"),
        AIModel(id: "mis-8b",      name: "Ministral 8B",   badge: "Fast",  apiProvider: "mistral", apiModel: "ministral-8b-latest"),
        AIModel(id: "pixtral",     name: "Pixtral 12B",    badge: nil,     apiProvider: "mistral", apiModel: "pixtral-12b-2409"),
    ]),
    AIProvider(id: "deepseek", name: "DeepSeek", icon: "magnifyingglass.circle.fill", colorHex: "#7B68EE", models: [
        AIModel(id: "ds-r1",       name: "DeepSeek R1",  badge: "Think", apiProvider: "merlin", apiModel: "deepseek-r1"),
    ]),
    AIProvider(id: "llama",    name: "Llama",    icon: "hare.fill",                   colorHex: "#9B59B6", models: [
        AIModel(id: "llama-405b",  name: "Llama 3.1 405B", badge: "Pro",  apiProvider: "github", apiModel: "Meta-Llama-3.1-405B-Instruct"),
        AIModel(id: "llama-8b",    name: "Llama 3.1 8B",   badge: "Fast", apiProvider: "github", apiModel: "Meta-Llama-3.1-8B-Instruct"),
        AIModel(id: "llama-70b",   name: "Llama 3.3 70B",  badge: nil,    apiProvider: "monica", apiModel: "llama-3.3-70b"),
    ]),
    AIProvider(id: "other",    name: "Other",    icon: "cpu.fill",                    colorHex: "#95A5A6", models: [
        AIModel(id: "perplexity-turbo", name: "Perplexity Turbo",      badge: "Fast",  apiProvider: "g4f", apiModel: "turbo"),
        AIModel(id: "perplexity-gpt41", name: "Perplexity GPT-4.1",    badge: nil,     apiProvider: "g4f", apiModel: "gpt41"),
        AIModel(id: "perplexity-gpt5",  name: "Perplexity GPT-5",      badge: "Pro",   apiProvider: "g4f", apiModel: "gpt5"),
        AIModel(id: "perplexity-o3",    name: "Perplexity O3",         badge: "Think", apiProvider: "g4f", apiModel: "o3"),
        AIModel(id: "perplexity-pro",   name: "Perplexity Pro",        badge: "Pro",   apiProvider: "g4f", apiModel: "pplx_pro"),
        AIModel(id: "kimi-k25",         name: "Kimi K2.5 Thinking",    badge: "Think", apiProvider: "merlin", apiModel: "kimi-k2.5-thinking"),
        AIModel(id: "kimi-k2",          name: "Kimi K2",               badge: nil,     apiProvider: "merlin", apiModel: "kimi-k2"),
        AIModel(id: "minimax",          name: "MiniMax M2.5",          badge: nil,     apiProvider: "merlin", apiModel: "minimax-m2.5"),
        AIModel(id: "glm",              name: "GLM",                   badge: nil,     apiProvider: "merlin", apiModel: "glm"),
        AIModel(id: "nemotron",         name: "Nemotron 70B",          badge: nil,     apiProvider: "monica", apiModel: "nemotron-70b"),
    ]),
]

// MARK: - Chat
struct ChatMessage: Identifiable {
    let id: UUID
    let role: MessageRole
    let text: String
    let image: UIImage?

    init(role: MessageRole, text: String, image: UIImage? = nil) {
        self.id = UUID()
        self.role = role
        self.text = text
        self.image = image
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
