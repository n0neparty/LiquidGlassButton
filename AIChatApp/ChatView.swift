import SwiftUI

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var chatId: String? = nil

    let provider: AIProvider
    let model: AIModel

    init(provider: AIProvider, model: AIModel) {
        self.provider = provider
        self.model = model
    }

    func send(_ text: String) async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isLoading = true
        messages.append(ChatMessage(role: .user, text: text))

        do {
            let response = try await APIService.shared.sendMessage(
                model: model, message: text, chatId: chatId
            )
            if let err = response.error {
                messages.append(ChatMessage(role: .error, text: err))
            } else {
                chatId = response.resolvedChatId
                messages.append(ChatMessage(role: .ai, text: response.text ?? ""))
            }
        } catch {
            // Демо режим — заглушка без API
            let demo = "[\(model.name)] Demo: API не подключён. Замени API_BASE в Models.swift на адрес своего сервера."
            messages.append(ChatMessage(role: .ai, text: demo))
        }
        isLoading = false
    }

    func clear() async {
        if let chatId { await APIService.shared.clearChat(apiProvider: model.apiProvider, chatId: chatId) }
        messages = []
        chatId = nil
    }
}

struct ChatView: View {
    let provider: AIProvider
    let model: AIModel
    let initialMessage: String

    @StateObject private var vm: ChatViewModel
    @State private var input = ""
    @FocusState private var focused: Bool
    @Environment(\.dismiss) private var dismiss

    init(provider: AIProvider, model: AIModel, initialMessage: String = "") {
        self.provider = provider
        self.model = model
        self.initialMessage = initialMessage
        _vm = StateObject(wrappedValue: ChatViewModel(provider: provider, model: model))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            RadialGradient(
                colors: [provider.color.opacity(0.12), .clear],
                center: .top, startRadius: 0, endRadius: 400
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Nav bar
                navBar

                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            if vm.messages.isEmpty { emptyState }
                            ForEach(vm.messages) { msg in
                                MessageBubble(msg: msg, color: provider.color)
                                    .id(msg.id)
                            }
                            if vm.isLoading { typingDots }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .onChange(of: vm.messages.count) { _ in
                        withAnimation { proxy.scrollTo(vm.messages.last?.id, anchor: .bottom) }
                    }
                }

                inputBar
                    .padding(.bottom, 8)
            }
        }
        .navigationBarHidden(true)
        .task {
            if !initialMessage.isEmpty {
                await vm.send(initialMessage)
            }
        }
    }

    // MARK: - Nav Bar
    var navBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
            }

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: provider.icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(provider.color)
                Text(model.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                if let badge = model.badge {
                    Text(badge)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(provider.color)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(provider.color.opacity(0.15), in: Capsule())
                }
            }

            Spacer()

            Button { Task { await vm.clear() } } label: {
                Image(systemName: "trash")
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: - Empty State
    var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: provider.icon)
                .font(.system(size: 52))
                .foregroundStyle(provider.color.opacity(0.6))
                .padding(.top, 60)
            Text("Ask \(provider.name) anything")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
            Text(model.name)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.4))
        }
    }

    // MARK: - Typing dots
    var typingDots: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(provider.color)
                    .frame(width: 7, height: 7)
                    .opacity(0.6)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Input Bar
    var inputBar: some View {
        HStack(spacing: 10) {
            Button { } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 36, height: 36)
                    .background(.white.opacity(0.08), in: Circle())
            }

            TextField("Ask anything", text: $input, axis: .vertical)
                .lineLimit(1...5)
                .font(.system(size: 16))
                .foregroundStyle(.white)
                .tint(provider.color)
                .focused($focused)
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(.white.opacity(0.07), in: Capsule())

            Button {
                let t = input.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !t.isEmpty else { return }
                input = ""
                Task { await vm.send(t) }
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(input.isEmpty ? .white.opacity(0.3) : .black)
                    .frame(width: 36, height: 36)
                    .background(input.isEmpty ? AnyShapeStyle(.white.opacity(0.08)) : AnyShapeStyle(Color.white), in: Circle())
            }
            .disabled(input.isEmpty || vm.isLoading)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
    }
}

// MARK: - Message Bubble
struct MessageBubble: View {
    let msg: ChatMessage
    let color: Color

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if msg.role == .user { Spacer(minLength: 60) }

            Text(msg.text)
                .font(.system(size: 15))
                .foregroundStyle(msg.role == .error ? Color(hex: "#f87171") : .white)
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background {
                    if msg.role == .user {
                        RoundedRectangle(cornerRadius: 20, style: .continuous).fill(color)
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(LinearGradient(colors: [.white.opacity(0.15), .clear], startPoint: .top, endPoint: .bottom))
                    } else {
                        RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.white.opacity(0.07))
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(.white.opacity(0.1), lineWidth: 0.8)
                    }
                }
                .textSelection(.enabled)

            if msg.role != .user { Spacer(minLength: 60) }
        }
    }
}
