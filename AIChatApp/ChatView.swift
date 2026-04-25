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
    @Namespace private var glassNamespace
    
    var body: some View {
        GlassEffectContainer {
            ZStack {
                // Black base
                Color.black.ignoresSafeArea()
                
                // Subtle radial gradient with lensing
                RadialGradient(
                    colors: [
                        provider.color.opacity(0.2),
                        provider.color.opacity(0.1),
                        .clear
                    ],
                    center: .init(x: 0.5, y: 0.2),
                    startRadius: 0,
                    endRadius: 400
                )
                .blur(radius: 90)
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Messages with fluid morphing
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(messages) { msg in
                                    MessageBubble(
                                        message: msg,
                                        providerColor: provider.color,
                                        namespace: glassNamespace
                                    )
                                    .id(msg.id)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 20)
                        }
                        .onChange(of: messages.count) { _, _ in
                            if let last = messages.last {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    proxy.scrollTo(last.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                    
                    // Input bar with interactive glass
                    inputBar
                }
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
    
    // MARK: Input Bar with Liquid Glass
    var inputBar: some View {
        HStack(spacing: 10) {
            Button { } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
            }
            .glassEffect()
            .glassEffectID("chatPlusBtn", in: glassNamespace)
            .interactive()
            
            Button { } label: {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
            }
            .glassEffect()
            .glassEffectID("chatLightBtn", in: glassNamespace)
            .interactive()
            
            TextField("Ask anything", text: $inputText)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(.primary)
                .tint(provider.color)
                .focused($inputFocused)
                .submitLabel(.send)
                .onSubmit { sendMessage() }
                .padding(.horizontal, 18)
                .padding(.vertical, 13)
                .glassEffect()
                .glassEffectID("chatTextField", in: glassNamespace)
            
            Button { sendMessage() } label: {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        .frame(width: 44, height: 44)
                        .background {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [.white, provider.color.opacity(0.3)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ))
                        }
                } else {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(inputText.isEmpty ? .secondary : .black)
                        .frame(width: 44, height: 44)
                        .background {
                            if inputText.isEmpty {
                                Circle().fill(.ultraThinMaterial)
                            } else {
                                Circle()
                                    .fill(LinearGradient(
                                        colors: [.white, provider.color.opacity(0.3)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ))
                            }
                        }
                }
            }
            .disabled(inputText.isEmpty || isLoading)
            .glassEffectID("chatSendBtn", in: glassNamespace)
            .interactive()
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: inputText.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .padding(.bottom, 8)
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

// MARK: - Message Bubble with Liquid Glass & Lensing
struct MessageBubble: View {
    let message: ChatMessage
    let providerColor: Color
    let namespace: Namespace.ID
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            if message.role == .user {
                Spacer(minLength: 60)
            }
            
            Text(message.text)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(message.role == .error ? .red : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .glassEffect()
                .glassEffectID("msg-\(message.id.uuidString)", in: namespace)
                .interactive()
            
            if message.role != .user {
                Spacer(minLength: 60)
            }
        }
    }
}
