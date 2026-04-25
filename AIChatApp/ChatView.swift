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
    @ObservedObject var debugSettings = DebugSettings.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Black base
            Color.black.ignoresSafeArea()
            
            // Subtle radial gradient
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
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: debugSettings.messageSpacing) {
                            ForEach(messages) { msg in
                                MessageBubble(message: msg, providerColor: provider.color)
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
                
                // Loading animation
                if isLoading {
                    ThinkingAnimation(color: provider.color)
                        .padding(.bottom, 12)
                }
                
                // Input bar
                inputBar
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 16, weight: .regular))
                    }
                    .foregroundStyle(.white)
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
    
    // MARK: Input Bar с системным liquid glass
    var inputBar: some View {
        HStack(spacing: debugSettings.inputBarSpacing) {
            Button { } label: {
                Image(systemName: "plus")
                    .font(.system(size: debugSettings.buttonIconSize, weight: .bold))
                    .frame(width: debugSettings.buttonSize, height: debugSettings.buttonSize)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            
            Button { } label: {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: debugSettings.buttonIconSize, weight: .bold))
                    .frame(width: debugSettings.buttonSize, height: debugSettings.buttonSize)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            
            // Text input with send button overlay
            ZStack(alignment: .trailing) {
                Capsule()
                    .fill(.ultraThinMaterial)
                
                TextField("Ask anything", text: $inputText)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.white)
                    .tint(provider.color)
                    .focused($inputFocused)
                    .submitLabel(.send)
                    .onSubmit { sendMessage() }
                    .padding(.leading, 18)
                    .padding(.trailing, 48)
                    .padding(.vertical, 13)
                
                // Send button overlay
                ZStack {
                    if inputText.isEmpty {
                        Button { } label: {
                            Image(systemName: "arrow.up")
                                .font(.system(size: debugSettings.buttonIconSize, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: debugSettings.buttonSize, height: debugSettings.buttonSize)
                        }
                        .buttonStyle(.glass)
                        .buttonBorderShape(.circle)
                        .disabled(true)
                    } else {
                        Button { sendMessage() } label: {
                            Image(systemName: "arrow.up")
                                .font(.system(size: debugSettings.buttonIconSize, weight: .bold))
                                .foregroundStyle(.black)
                                .frame(width: debugSettings.buttonSize, height: debugSettings.buttonSize)
                        }
                        .buttonStyle(.plain)
                        .background(Circle().fill(.white))
                    }
                }
                .frame(width: debugSettings.buttonSize, height: debugSettings.buttonSize)
                .padding(.trailing, 5)
            }
            .frame(height: 44)
        }
        .padding(.horizontal, debugSettings.inputBarHorizontalPadding)
        .padding(.vertical, debugSettings.inputBarVerticalPadding)
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

// MARK: - Thinking Animation
struct ThinkingAnimation: View {
    let color: Color
    @State private var phase: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                    .scaleEffect(scale(for: index))
                    .opacity(opacity(for: index))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                phase = 1
            }
        }
    }
    
    private func scale(for index: Int) -> CGFloat {
        let progress = (phase + CGFloat(index) * 0.33).truncatingRemainder(dividingBy: 1)
        return 1 + sin(progress * .pi) * 0.5
    }
    
    private func opacity(for index: Int) -> Double {
        let progress = (phase + CGFloat(index) * 0.33).truncatingRemainder(dividingBy: 1)
        return 0.4 + sin(progress * .pi) * 0.6
    }
}

// MARK: - Message Bubble
struct MessageBubble: View {
    let message: ChatMessage
    let providerColor: Color
    @ObservedObject var debugSettings = DebugSettings.shared
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            if message.role == .user {
                Spacer(minLength: 60)
            }
            
            Text(message.text)
                .font(.system(size: debugSettings.messageTextSize, weight: .regular))
                .foregroundStyle(message.role == .error ? .red : .white)
                .padding(.horizontal, debugSettings.messageBubbleHorizontalPadding)
                .padding(.vertical, debugSettings.messageBubbleVerticalPadding)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: debugSettings.messageBubbleCornerRadius, style: .continuous))
            
            if message.role != .user {
                Spacer(minLength: 60)
            }
        }
    }
}
