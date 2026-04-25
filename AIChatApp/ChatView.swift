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
                        LazyVStack(spacing: 16) {
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
                    Image(systemName: "chevron.left")
                        .font(.title3.bold())
                        .frame(width: debugSettings.buttonSize, height: debugSettings.buttonSize)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
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
        HStack(spacing: 10) {
            Button { } label: {
                Image(systemName: "plus")
                    .font(.title3.bold())
                    .frame(width: debugSettings.buttonSize, height: debugSettings.buttonSize)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            
            Button { } label: {
                Image(systemName: "lightbulb.fill")
                    .font(.title3.bold())
                    .frame(width: debugSettings.buttonSize, height: debugSettings.buttonSize)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            
            ZStack {
                Capsule()
                    .fill(.ultraThinMaterial)
                
                TextField("Ask anything", text: $inputText)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.white)
                    .tint(provider.color)
                    .focused($inputFocused)
                    .submitLabel(.send)
                    .onSubmit { sendMessage() }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 13)
            }
            .frame(height: 44)
            
            // Send button - полностью белая когда активна
            if isLoading {
                Button { } label: {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        .frame(width: debugSettings.buttonSize, height: debugSettings.buttonSize)
                        .background(Circle().fill(.white))
                }
                .disabled(true)
            } else if inputText.isEmpty {
                Button { } label: {
                    Image(systemName: "arrow.up")
                        .font(.title3.bold())
                        .frame(width: debugSettings.buttonSize, height: debugSettings.buttonSize)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .disabled(true)
            } else {
                Button { sendMessage() } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(width: debugSettings.buttonSize, height: debugSettings.buttonSize)
                        .background(Circle().fill(.white))
                }
            }
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

// MARK: - Message Bubble
struct MessageBubble: View {
    let message: ChatMessage
    let providerColor: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            if message.role == .user {
                Spacer(minLength: 60)
            }
            
            Text(message.text)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(message.role == .error ? .red : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            
            if message.role != .user {
                Spacer(minLength: 60)
            }
        }
    }
}
