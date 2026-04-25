import SwiftUI

struct ChatView: View {
    let provider: AIProvider
    let model: AIModel
    let initialMessage: String
    
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var chatId: String?
    @State private var isLoading = false
    @FocusState private var inputFocused: Bool
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { msg in
                                MessageBubble(message: msg, providerColor: provider.color)
                                    .id(msg.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) { _, _ in
                        if let last = messages.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                }
                
                // Input bar
                HStack(spacing: 10) {
                    TextField("Message", text: $inputText)
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                        .tint(provider.color)
                        .focused($inputFocused)
                        .submitLabel(.send)
                        .onSubmit { sendMessage() }
                        .padding(.horizontal, 16).padding(.vertical, 11)
                        .liquidGlass(radius: 22, intensity: 0.08)
                    
                    Button { sendMessage() } label: {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(inputText.isEmpty ? .white.opacity(0.3) : .black)
                            .frame(width: 38, height: 38)
                            .background {
                                if inputText.isEmpty {
                                    Circle().fill(.white.opacity(0.08))
                                } else {
                                    Circle().fill(Color.white)
                                }
                            }
                    }
                    .disabled(inputText.isEmpty || isLoading)
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
            }
        }
        .navigationTitle(model.name)
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .task {
            if !initialMessage.isEmpty {
                inputText = initialMessage
                sendMessage()
            }
        }
    }
    
    private func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let userMsg = inputText
        inputText = ""
        messages.append(ChatMessage(role: .user, text: userMsg))
        isLoading = true
        
        Task {
            do {
                let response = try await APIService.shared.sendMessage(
                    model: model,
                    message: userMsg,
                    chatId: chatId
                )
                
                if let text = response.text {
                    messages.append(ChatMessage(role: .ai, text: text))
                }
                if let id = response.resolvedChatId {
                    chatId = id
                }
                if let error = response.error {
                    messages.append(ChatMessage(role: .error, text: error))
                }
            } catch {
                messages.append(ChatMessage(role: .error, text: "Error: \(error.localizedDescription)"))
            }
            isLoading = false
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    let providerColor: Color
    
    var body: some View {
        HStack {
            if message.role == .user { Spacer() }
            
            Text(message.text)
                .font(.system(size: 15))
                .foregroundStyle(message.role == .error ? .red : .white)
                .padding(.horizontal, 14).padding(.vertical, 10)
                .liquidGlass(
                    color: message.role == .user ? providerColor : .white,
                    radius: 16,
                    intensity: message.role == .user ? 0.15 : 0.08
                )
            
            if message.role != .user { Spacer() }
        }
    }
}
