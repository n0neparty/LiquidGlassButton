import SwiftUI

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var chatId: String? = nil

    let provider: Provider
    let model: AIModel

    init(provider: Provider, model: AIModel) {
        self.provider = provider
        self.model = model
    }

    func send(_ text: String) async {
        guard !text.isEmpty, !isLoading else { return }
        isLoading = true

        messages.append(ChatMessage(role: .user, text: text))

        do {
            let response = try await APIService.shared.sendMessage(
                provider: provider.id,
                model: model.id,
                message: text,
                chatId: chatId
            )
            if let err = response.error {
                messages.append(ChatMessage(role: .error, text: err))
            } else {
                chatId = response.resolvedChatId
                messages.append(ChatMessage(role: .ai, text: response.text))
            }
        } catch {
            messages.append(ChatMessage(role: .error, text: error.localizedDescription))
        }
        isLoading = false
    }

    func clear() async {
        if let chatId {
            await APIService.shared.clearChat(provider: provider.id, chatId: chatId)
        }
        messages = []
        chatId = nil
    }
}

struct ChatView: View {
    let provider: Provider
    let model: AIModel

    @StateObject private var vm: ChatViewModel
    @State private var input = ""
    @FocusState private var focused: Bool

    init(provider: Provider, model: AIModel) {
        self.provider = provider
        self.model = model
        _vm = StateObject(wrappedValue: ChatViewModel(provider: provider, model: model))
    }

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(hex: "#0a0a0f"), Color(hex: "#0f0a1a")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if vm.messages.isEmpty {
                                emptyState
                            }
                            ForEach(vm.messages) { msg in
                                MessageBubble(message: msg, providerColor: Color(hex: provider.color))
                                    .id(msg.id)
                            }
                            if vm.isLoading {
                                TypingIndicator(color: Color(hex: provider.color))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .onChange(of: vm.messages.count) { _ in
                        if let last = vm.messages.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                }

                // Input bar
                inputBar
            }
        }
        .navigationTitle(model.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await vm.clear() }
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
    }

    var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48))
                .foregroundStyle(Color(hex: provider.color).opacity(0.6))
            Text("Начни диалог")
                .font(.title3.bold())
                .foregroundStyle(.white)
            Text("\(provider.name) · \(model.displayName)")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.4))
        }
        .padding(.top, 80)
    }

    var inputBar: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Сообщение...", text: $input, axis: .vertical)
                .lineLimit(1...5)
                .font(.system(size: 16))
                .foregroundStyle(.white)
                .tint(Color(hex: provider.color))
                .focused($focused)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(.white.opacity(0.12), lineWidth: 0.8)
                }

            GlassSendButton(action: {
                let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
                input = ""
                Task { await vm.send(text) }
            }, disabled: input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || vm.isLoading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Message Bubble
struct MessageBubble: View {
    let message: ChatMessage
    let providerColor: Color

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 60) }

            Text(message.text)
                .font(.system(size: 15))
                .foregroundStyle(message.role == .error ? Color(hex: "#f87171") : .white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background {
                    if message.role == .user {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(providerColor)
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(LinearGradient(colors: [.white.opacity(0.2), .clear], startPoint: .top, endPoint: .bottom))
                    } else {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(.ultraThinMaterial)
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(.white.opacity(0.1), lineWidth: 0.8)
                    }
                }

            if message.role != .user { Spacer(minLength: 60) }
        }
    }
}

// MARK: - Typing Indicator
struct TypingIndicator: View {
    let color: Color
    @State private var phase = 0

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(color)
                    .frame(width: 7, height: 7)
                    .scaleEffect(phase == i ? 1.3 : 0.8)
                    .animation(.easeInOut(duration: 0.4).repeatForever().delay(Double(i) * 0.15), value: phase)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear { phase = 2 }
    }
}
