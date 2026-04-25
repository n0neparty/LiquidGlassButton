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
    AIProvider(id: "grok", name: "Grok", icon: "bolt.fill", colorHex: "#1D9BF0", models: [
        AIModel(id: "grok-fast",    name: "Grok 4.1 Fast",  badge: "Fast",  apiProvider: "merlin",  apiModel: "grok-4.1-fast"),
        AIModel(id: "grok-4",       name: "Grok 4",         badge: nil,     apiProvider: "g4f",     apiModel: "grok"),
        AIModel(id: "grok4-pplx",   name: "Grok 4 (Perplexity)", badge: "Pro", apiProvider: "g4f", apiModel: "grok4"),
    ]),
    AIProvider(id: "chatgpt", name: "ChatGPT", icon: "sparkles", colorHex: "#10A37F", models: [
        AIModel(id: "gpt4o-mini",   name: "GPT-4o mini",    badge: "Fast",  apiProvider: "github",  apiModel: "gpt-4o-mini"),
        AIModel(id: "gpt4o",        name: "GPT-4o",         badge: nil,     apiProvider: "github",  apiModel: "gpt-4o"),
        AIModel(id: "gpt4o-pplx",   name: "GPT-4o (Perplexity)", badge: nil, apiProvider: "g4f",   apiModel: "gpt4o"),
        AIModel(id: "gpt41",        name: "GPT-4.1",        badge: nil,     apiProvider: "g4f",     apiModel: "gpt41"),
        AIModel(id: "gpt41-nano",   name: "GPT-4.1 Nano",   badge: "Tiny",  apiProvider: "monica",  apiModel: "gpt-4.1-nano"),
        AIModel(id: "gpt45",        name: "GPT-4.5",        badge: nil,     apiProvider: "g4f",     apiModel: "gpt45"),
        AIModel(id: "gpt5",         name: "GPT-5",          badge: "Pro",   apiProvider: "g4f",     apiModel: "gpt5"),
        AIModel(id: "gpt5-think",   name: "GPT-5 Thinking", badge: "Think", apiProvider: "g4f",     apiModel: "gpt5_thinking"),
        AIModel(id: "gpt54-nano",   name: "GPT-5.4 Nano",   badge: "Tiny",  apiProvider: "g4f",     apiModel: "openai"),
        AIModel(id: "gpt5-mini",    name: "GPT-5 Mini",     badge: nil,     apiProvider: "merlin",  apiModel: "gpt-5-mini"),
        AIModel(id: "gpt54",        name: "GPT-5.4",        badge: "Pro",   apiProvider: "merlin",  apiModel: "gpt-5.4"),
        AIModel(id: "gpt52",        name: "GPT-5.2",        badge: nil,     apiProvider: "merlin",  apiModel: "gpt-5.2"),
        AIModel(id: "gpt51",        name: "GPT-5.1",        badge: nil,     apiProvider: "merlin",  apiModel: "gpt-5.1"),
        AIModel(id: "o3",           name: "O3",             badge: "Think", apiProvider: "g4f",     apiModel: "o3"),
        AIModel(id: "o3pro",        name: "O3 Pro",         badge: "Think", apiProvider: "g4f",     apiModel: "o3pro"),
        AIModel(id: "o4mini",       name: "O4 Mini",        badge: "Fast",  apiProvider: "g4f",     apiModel: "o4mini"),
        AIModel(id: "openai-lg",    name: "OpenAI Large",   badge: nil,     apiProvider: "g4f",     apiModel: "openai-large"),
    ]),
    AIProvider(id: "gemini", name: "Gemini", icon: "star.fill", colorHex: "#4285F4", models: [
        AIModel(id: "gem3-flash",       name: "Gemini 3 Flash",           badge: "Fast", apiProvider: "g4f",    apiModel: "gemini-3-flash-preview"),
        AIModel(id: "gem3-flash-s",     name: "Gemini 3 Flash Search",    badge: "Web",  apiProvider: "g4f",    apiModel: "gemini-3-flash-preview:search"),
        AIModel(id: "gem3-lite",        name: "Gemini 3 Flash Lite",      badge: "Lite", apiProvider: "g4f",    apiModel: "gemini-3-flash-lite-preview"),
        AIModel(id: "gem3-lite-s",      name: "Gemini 3 Lite Search",     badge: "Web",  apiProvider: "g4f",    apiModel: "gemini-3-flash-lite-preview:search"),
        AIModel(id: "gem31-pro",        name: "Gemini 3.1 Pro",           badge: "Pro",  apiProvider: "g4f",    apiModel: "gemini-3.1-pro-preview"),
        AIModel(id: "gem31-pro-s",      name: "Gemini 3.1 Pro Search",    badge: "Web",  apiProvider: "g4f",    apiModel: "gemini-3.1-pro-preview:search"),
        AIModel(id: "gem31-pro-m",      name: "Gemini 3.1 Pro (Merlin)",  badge: nil,    apiProvider: "merlin", apiModel: "gemini-3.1-pro"),
        AIModel(id: "gem30-pro",        name: "Gemini 3.0 Pro",           badge: nil,    apiProvider: "merlin", apiModel: "gemini-3.0-pro"),
        AIModel(id: "gem25-flash",      name: "Gemini 2.5 Flash",         badge: nil,    apiProvider: "gemini", apiModel: "gemini-2.5-flash"),
        AIModel(id: "gem25-lite",       name: "Gemini 2.5 Flash Lite",    badge: "Lite", apiProvider: "gemini", apiModel: "gemini-2.5-flash-lite"),
        AIModel(id: "gem-fast",         name: "Gemini Fast",              badge: "Fast", apiProvider: "g4f",    apiModel: "gemini-fast"),
        AIModel(id: "gem-search",       name: "Gemini Search",            badge: "Web",  apiProvider: "g4f",    apiModel: "gemini-search"),
    ]),
    AIProvider(id: "claude", name: "Claude", icon: "wand.and.stars", colorHex: "#CC8B65", models: [
        AIModel(id: "sonnet45",         name: "Claude 4.5 Sonnet",          badge: "Pro",   apiProvider: "g4f", apiModel: "claude45sonnet"),
        AIModel(id: "sonnet45-think",   name: "Claude 4.5 Thinking",        badge: "Think", apiProvider: "g4f", apiModel: "claude45sonnetthinking"),
        AIModel(id: "opus41-think",     name: "Claude 4.1 Opus Thinking",   badge: "Think", apiProvider: "g4f", apiModel: "claude41opusthinking"),
        AIModel(id: "opus40",           name: "Claude 4.0 Opus",            badge: "Pro",   apiProvider: "g4f", apiModel: "claude40opus"),
        AIModel(id: "opus40-think",     name: "Claude 4.0 Opus Thinking",   badge: "Think", apiProvider: "g4f", apiModel: "claude40opusthinking"),
        AIModel(id: "sonnet37-think",   name: "Claude 3.7 Thinking",        badge: "Think", apiProvider: "g4f", apiModel: "claude37sonnetthinking"),
        AIModel(id: "sonnet40-res",     name: "Claude 4.0 Sonnet Research", badge: "Think", apiProvider: "g4f", apiModel: "claude40sonnet_research"),
        AIModel(id: "sonnet40-think-res", name: "Claude 4.0 Sonnet Think Research", badge: "Think", apiProvider: "g4f", apiModel: "claude40sonnetthinking_research"),
        AIModel(id: "opus40-res",       name: "Claude 4.0 Opus Research",   badge: "Think", apiProvider: "g4f", apiModel: "claude40opus_research"),
        AIModel(id: "opus40-think-res", name: "Claude 4.0 Opus Think Research", badge: "Think", apiProvider: "g4f", apiModel: "claude40opusthinking_research"),
    ]),
    AIProvider(id: "mistral", name: "Mistral", icon: "wind", colorHex: "#FF6B35", models: [
        AIModel(id: "mis-small",   name: "Mistral Small",  badge: nil,    apiProvider: "mistral", apiModel: "mistral-small-latest"),
        AIModel(id: "mis-large",   name: "Mistral Large",  badge: "Pro",  apiProvider: "mistral", apiModel: "mistral-large-latest"),
        AIModel(id: "mis-nemo",    name: "Mistral Nemo",   badge: nil,    apiProvider: "mistral", apiModel: "open-mistral-nemo"),
        AIModel(id: "codestral",   name: "Codestral",      badge: "Code", apiProvider: "mistral", apiModel: "codestral-latest"),
        AIModel(id: "mis-3b",      name: "Ministral 3B",   badge: "Tiny", apiProvider: "mistral", apiModel: "ministral-3b-latest"),
        AIModel(id: "mis-8b",      name: "Ministral 8B",   badge: "Fast", apiProvider: "mistral", apiModel: "ministral-8b-latest"),
        AIModel(id: "pixtral",     name: "Pixtral 12B",    badge: nil,    apiProvider: "mistral", apiModel: "pixtral-12b-2409"),
    ]),
    AIProvider(id: "deepseek", name: "DeepSeek", icon: "magnifyingglass.circle.fill", colorHex: "#7B68EE", models: [
        AIModel(id: "ds-r1",       name: "DeepSeek R1",    badge: "Think", apiProvider: "merlin", apiModel: "deepseek-r1"),
    ]),
    AIProvider(id: "llama", name: "Llama", icon: "hare.fill", colorHex: "#9B59B6", models: [
        AIModel(id: "llama-405b",  name: "Llama 3.1 405B", badge: "Pro",  apiProvider: "github", apiModel: "Meta-Llama-3.1-405B-Instruct"),
        AIModel(id: "llama-8b",    name: "Llama 3.1 8B",   badge: "Fast", apiProvider: "github", apiModel: "Meta-Llama-3.1-8B-Instruct"),
        AIModel(id: "llama-70b",   name: "Llama 3.3 70B",  badge: nil,    apiProvider: "monica", apiModel: "llama-3.3-70b"),
    ]),
    AIProvider(id: "perplexity", name: "Perplexity", icon: "magnifyingglass", colorHex: "#20B2AA", models: [
        AIModel(id: "pplx-turbo",  name: "Perplexity Turbo",       badge: "Fast",  apiProvider: "g4f", apiModel: "turbo"),
        AIModel(id: "pplx-pro",    name: "Perplexity Pro",         badge: "Pro",   apiProvider: "g4f", apiModel: "pplx_pro"),
        AIModel(id: "pplx-pro-up", name: "Perplexity Pro+",        badge: "Pro",   apiProvider: "g4f", apiModel: "pplx_pro_upgraded"),
        AIModel(id: "pplx-alpha",  name: "Perplexity Alpha",       badge: nil,     apiProvider: "g4f", apiModel: "pplx_alpha"),
        AIModel(id: "pplx-beta",   name: "Perplexity Beta",        badge: nil,     apiProvider: "g4f", apiModel: "pplx_beta"),
        AIModel(id: "pplx-comet",  name: "Comet Max",              badge: nil,     apiProvider: "g4f", apiModel: "comet_max_assistant"),
        AIModel(id: "o3-res",      name: "O3 Research",            badge: "Think", apiProvider: "g4f", apiModel: "o3_research"),
        AIModel(id: "o3pro-res",   name: "O3 Pro Research",        badge: "Think", apiProvider: "g4f", apiModel: "o3pro_research"),
        AIModel(id: "o3-labs",     name: "O3 Labs",                badge: nil,     apiProvider: "g4f", apiModel: "o3_labs"),
        AIModel(id: "o3pro-labs",  name: "O3 Pro Labs",            badge: nil,     apiProvider: "g4f", apiModel: "o3pro_labs"),
    ]),
    AIProvider(id: "other", name: "Other", icon: "cpu.fill", colorHex: "#95A5A6", models: [
        AIModel(id: "kimi-k25",    name: "Kimi K2.5 Thinking",     badge: "Think", apiProvider: "merlin", apiModel: "kimi-k2.5-thinking"),
        AIModel(id: "kimi-k2",     name: "Kimi K2",                badge: nil,     apiProvider: "merlin", apiModel: "kimi-k2"),
        AIModel(id: "minimax",     name: "MiniMax M2.5",           badge: nil,     apiProvider: "merlin", apiModel: "minimax-m2.5"),
        AIModel(id: "glm",         name: "GLM",                    badge: nil,     apiProvider: "merlin", apiModel: "glm"),
        AIModel(id: "nemotron",    name: "Nemotron 70B",           badge: nil,     apiProvider: "monica", apiModel: "nemotron-70b"),
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
