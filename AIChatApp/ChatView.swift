import SwiftUI

struct ChatView: View {
    let provider: AIProvider
    let model: AIModel
    let initialMessage: String
    var initialImages: [UIImage] = []
    var initialThinkingMode: Bool = false

    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var chatId: String?
    @State private var isLoading = false
    @State private var streamingText = ""
    @State private var isStreaming = false
    @State private var selectedImages: [UIImage] = []
    @State private var showImagePicker = false
    @State private var thinkingMode = false
    
    // Отдельное состояние для волны — чтобы анимация надёжно перезапускалась
    @State private var showWave = false

    @FocusState private var inputFocused: Bool
    @Environment(\.dismiss) var dismiss

    var ds: DebugSettings { DebugSettings.shared }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            RadialGradient(
                colors: [provider.color.opacity(0.2), provider.color.opacity(0.1), .clear],
                center: .init(x: 0.5, y: 0.2),
                startRadius: 0,
                endRadius: 400
            )
            .blur(radius: 90)
            .ignoresSafeArea()

            VStack(spacing: 0) {
                messageList
                
                // Волна теперь управляется через dedicated состояние
                if showWave {
                    WaveLoadingAnimation(color: provider.color)
                        .padding(.bottom, 12)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
                
                inputBar
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
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
            thinkingMode = initialThinkingMode
            selectedImages = initialImages
            if !initialMessage.isEmpty {
                inputText = initialMessage
                sendMessage()
            }
        }
    }

    var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: ds.messageSpacing) {
                    ForEach(messages) { msg in
                        MessageBubble(message: msg, providerColor: provider.color)
                            .id(msg.id)
                    }
                    
                    if isStreaming && !streamingText.isEmpty {
                        MessageBubble(
                            message: ChatMessage(role: .ai, text: streamingText),
                            providerColor: provider.color
                        )
                        .id("streaming")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .onChange(of: messages.count) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: streamingText) { _, _ in
                if isStreaming {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo("streaming", anchor: .bottom)
                    }
                }
            }
        }
    }

    var inputBar: some View {
        VStack(spacing: 0) {
            if !selectedImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 64, height: 64)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                
                                Button {
                                    selectedImages.remove(at: index)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundStyle(.white)
                                        .background(Circle().fill(.black.opacity(0.6)))
                                }
                                .offset(x: 8, y: -8)
                            }
                        }
                    }
                    .padding(.horizontal, ds.inputBarHorizontalPadding)
                    .padding(.top, 10)
                }
                .padding(.bottom, 8)
            }

            HStack(spacing: 0) {
                // Кнопки слева
                HStack(spacing: 6) {
                    Button { showImagePicker = true } label: {
                        Image(systemName: "plus")
                            .font(.system(size: ds.buttonIconSize, weight: .bold))
                            .frame(width: ds.buttonSize, height: ds.buttonSize)
                    }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)

                    Button { thinkingMode.toggle() } label: {
                        Image(systemName: thinkingMode ? "lightbulb.fill" : "lightbulb")
                            .font(.system(size: ds.buttonIconSize, weight: .bold))
                            .foregroundStyle(thinkingMode ? provider.color : .white)
                            .frame(width: ds.buttonSize, height: ds.buttonSize)
                    }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                }

                Spacer().frame(width: 10)

                // Поле ввода
                TextField("Ask anything", text: $inputText)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.white)
                    .tint(provider.color)
                    .focused($inputFocused)
                    .submitLabel(.send)
                    .onSubmit { sendMessage() }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 13)
                    .frame(height: 44)
                    .background(Capsule().fill(.ultraThinMaterial))
                    .layoutPriority(-1)

                Spacer().frame(width: ds.inputBarSpacing)

                // Кнопка отправки
                if inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button { } label: {
                        Image(systemName: "arrow.up")
                            .font(.system(size: ds.buttonIconSize, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: ds.buttonSize, height: ds.buttonSize)
                    }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                    .disabled(true)
                } else {
                    Button { sendMessage() } label: {
                        Image(systemName: "arrow.up")
                            .font(.system(size: ds.buttonIconSize, weight: .bold))
                            .foregroundStyle(.black)
                            .frame(width: ds.buttonSize, height: ds.buttonSize)
                    }
                    .buttonStyle(.plain)
                    .background(Circle().fill(.white))
                }
            }
            .padding(.horizontal, ds.inputBarHorizontalPadding)
            .padding(.vertical, ds.inputBarVerticalPadding)
            .padding(.bottom, 8)
        }
        .sheet(isPresented: $showImagePicker) {
            AppImagePicker(images: $selectedImages)
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
            if let last = messages.last {
                proxy.scrollTo(last.id, anchor: .bottom)
            } else if isStreaming {
                proxy.scrollTo("streaming", anchor: .bottom)
            }
        }
    }

    private func sendMessage() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let image = selectedImages.first
        let useThinking = thinkingMode

        // Сбрасываем ввод
        inputText = ""
        selectedImages = []
        inputFocused = false

        // Добавляем сообщение пользователя
        let userMessage = ChatMessage(role: .user, text: trimmed, image: image)
        messages.append(userMessage)
        
        // Запускаем волну
        isLoading = true
        showWave = true
        isStreaming = false
        streamingText = ""

        Task {
            do {
                // Thinking mode (если включён)
                if useThinking {
                    _ = try await APIService.shared.sendMessage(
                        model: model,
                        message: "You are in deep thinking mode. Think carefully before answering. Reply only '1337' to confirm.",
                        chatId: chatId,
                        image: nil
                    )
                }

                // Основной запрос
                let response = try await APIService.shared.sendMessage(
                    model: model,
                    message: trimmed,
                    chatId: chatId,
                    image: image
                )
                
                if let id = response.resolvedChatId {
                    chatId = id
                }

                if let err = response.error {
                    messages.append(ChatMessage(role: .error, text: err))
                    isLoading = false
                    showWave = false
                } else if let fullText = response.text {
                    let cleaned = cleanThinkingTags(fullText)
                    
                    // Начинаем стриминг — скрываем волну
                    await MainActor.run {
                        isLoading = false
                        showWave = false
                        isStreaming = true
                        streamingText = ""
                    }
                    
                    await streamWords(cleaned)
                }
            } catch {
                await MainActor.run {
                    messages.append(ChatMessage(role: .error, text: error.localizedDescription))
                    isLoading = false
                    showWave = false
                }
            }
        }
    }

    private func streamWords(_ text: String) async {
        let words = text.split(separator: " ")
        var current = ""
        
        for (index, word) in words.enumerated() {
            current += (index == 0 ? "" : " ") + word
            await MainActor.run {
                streamingText = current
            }
            try? await Task.sleep(for: .milliseconds(30)) // плавность стриминга
        }
        
        await MainActor.run {
            // Завершаем стриминг
            messages.append(ChatMessage(role: .ai, text: text))
            streamingText = ""
            isStreaming = false
            isLoading = false
            showWave = false
        }
    }

    private func cleanThinkingTags(_ text: String) -> String {
        // Убираем возможные теги thinking mode, если они есть
        var cleaned = text
        cleaned = cleaned.replacingOccurrences(of: "<think>.*?</think>", with: "", options: .regularExpression)
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned
    }
}
