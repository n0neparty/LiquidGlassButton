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
    @FocusState private var inputFocused: Bool
    @Environment(\.dismiss) var dismiss

    // Access shared settings
    var ds: DebugSettings { DebugSettings.shared }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            RadialGradient(
                colors: [provider.color.opacity(0.2), provider.color.opacity(0.1), .clear],
                center: .init(x: 0.5, y: 0.2), startRadius: 0, endRadius: 400
            )
            .blur(radius: 90).ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: ds.messageSpacing) {
                            ForEach(messages) { msg in
                                MessageBubble(message: msg, providerColor: provider.color)
                                    .id(msg.id)
                            }
                            // Streaming bubble
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
                        if let last = messages.last {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: streamingText) { _, _ in
                        withAnimation { proxy.scrollTo("streaming", anchor: .bottom) }
                    }
                }

                if isLoading {
                    WaveLoadingAnimation(color: provider.color)
                        .padding(.bottom, 12)
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

    var inputBar: some View {
        VStack(spacing: 0) {
            if !selectedImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: image)
                                    .resizable().scaledToFill()
                                    .frame(width: 64, height: 64)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                Button { selectedImages.remove(at: index) } label: {
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
                HStack(spacing: 6) {
                    Button { showImagePicker = true } label: {
                        Image(systemName: "plus")
                            .font(.system(size: ds.buttonIconSize, weight: .bold))
                            .frame(width: ds.buttonSize, height: ds.buttonSize)
                    }
                    .buttonStyle(.glass).buttonBorderShape(.circle)

                    Button { thinkingMode.toggle() } label: {
                        Image(systemName: thinkingMode ? "lightbulb.fill" : "lightbulb")
                            .font(.system(size: ds.buttonIconSize, weight: .bold))
                            .foregroundStyle(thinkingMode ? provider.color : .white)
                            .frame(width: ds.buttonSize, height: ds.buttonSize)
                    }
                    .buttonStyle(.glass).buttonBorderShape(.circle)
                }

                Spacer().frame(width: 10)

                TextField("Ask anything", text: $inputText)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.white)
                    .tint(provider.color)
                    .focused($inputFocused)
                    .submitLabel(.send)
                    .onSubmit { sendMessage() }
                    .padding(.horizontal, 18).padding(.vertical, 13)
                    .frame(height: 44)
                    .background(Capsule().fill(.ultraThinMaterial))
                    .layoutPriority(-1)

                Spacer().frame(width: ds.inputBarSpacing)

                if inputText.isEmpty {
                    Button { } label: {
                        Image(systemName: "arrow.up")
                            .font(.system(size: ds.buttonIconSize, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: ds.buttonSize, height: ds.buttonSize)
                    }
                    .buttonStyle(.glass).buttonBorderShape(.circle)
                    .disabled(true)
                    .frame(width: ds.buttonSize, height: ds.buttonSize)
                    .layoutPriority(1)
                } else {
                    Button { sendMessage() } label: {
                        Image(systemName: "arrow.up")
                            .font(.system(size: ds.buttonIconSize, weight: .bold))
                            .foregroundStyle(.black)
                            .frame(width: ds.buttonSize, height: ds.buttonSize)
                    }
                    .buttonStyle(.plain)
                    .background(Circle().fill(.white))
                    .frame(width: ds.buttonSize, height: ds.buttonSize)
                    .layoutPriority(1)
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

    private func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let userMsg = inputText
        let imagesToSend = selectedImages
        let useThinking = thinkingMode
        inputText = ""
        selectedImages = []
        messages.append(ChatMessage(role: .user, text: userMsg, image: imagesToSend.first))
        isLoading = true

        Task {
            do {
                if useThinking {
                    let thinkingPrompt = "You are now in deep thinking mode. Think step by step. If you understand, respond with exactly: 1337"
                    let thinkingResponse = try await APIService.shared.sendMessage(
                        model: model, message: thinkingPrompt, chatId: chatId, image: nil
                    )
                    if let id = thinkingResponse.resolvedChatId { chatId = id }

                    let response = try await APIService.shared.sendMessage(
                        model: model, message: userMsg, chatId: chatId,
                        image: imagesToSend.first
                    )
                    handleResponse(response)
                } else {
                    let response = try await APIService.shared.sendMessage(
                        model: model, message: userMsg, chatId: chatId,
                        image: imagesToSend.first
                    )
                    handleResponse(response)
                }
            } catch {
                messages.append(ChatMessage(role: .error, text: "Error: \(error.localizedDescription)"))
            }
            isLoading = false
        }
    }

    private func handleResponse(_ response: ChatResponse) {
        if let text = response.text {
            if let id = response.resolvedChatId { chatId = id }
            // Animate text word by word
            let words = text.components(separatedBy: " ")
            isStreaming = true
            streamingText = ""
            Task {
                for (i, word) in words.enumerated() {
                    try? await Task.sleep(nanoseconds: 30_000_000)
                    streamingText += (i == 0 ? "" : " ") + word
                }
                // Commit to messages
                messages.append(ChatMessage(role: .ai, text: text))
                streamingText = ""
                isStreaming = false
            }
        }
        if let id = response.resolvedChatId { chatId = id }
        if let error = response.error { messages.append(ChatMessage(role: .error, text: error)) }
    }
}

// MARK: - Wave Loading Animation
struct WaveLoadingAnimation: View {
    let color: Color
    @State private var phase: CGFloat = 0
    private let barCount = 5
    private let barWidth: CGFloat = 4
    private let maxHeight: CGFloat = 22
    private let minHeight: CGFloat = 5

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<barCount, id: \.self) { i in
                RoundedRectangle(cornerRadius: barWidth / 2)
                    .fill(color)
                    .frame(width: barWidth, height: barHeight(for: i))
                    .animation(
                        .easeInOut(duration: 0.5)
                        .repeatForever(autoreverses: true)
                        .delay(Double(i) * 0.1),
                        value: phase
                    )
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .onAppear { phase = 1 }
    }

    private func barHeight(for index: Int) -> CGFloat {
        let offset = CGFloat(index) / CGFloat(barCount - 1)
        let wave = sin((offset + phase) * .pi)
        return minHeight + (maxHeight - minHeight) * ((wave + 1) / 2)
    }
}

// MARK: - Message Bubble
struct MessageBubble: View {
    let message: ChatMessage
    let providerColor: Color

    var ds: DebugSettings { DebugSettings.shared }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            if message.role == .user { Spacer(minLength: 60) }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                // Image above message if present
                if let image = message.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 180, height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: ds.messageBubbleCornerRadius, style: .continuous))
                }
                
                // Text bubble
                if !message.text.isEmpty {
                    Text(message.text)
                        .font(.system(size: ds.messageTextSize, weight: .regular))
                        .foregroundStyle(message.role == .error ? .red : .white)
                        .padding(.horizontal, ds.messageBubbleHorizontalPadding)
                        .padding(.vertical, ds.messageBubbleVerticalPadding)
                        .background(
                            message.role == .ai
                                ? Color(white: 0.12)
                                : .ultraThinMaterial,
                            in: RoundedRectangle(cornerRadius: ds.messageBubbleCornerRadius, style: .continuous)
                        )
                }
            }
            
            if message.role != .user { Spacer(minLength: 60) }
        }
    }
}

// MARK: - Image Picker
struct AppImagePicker: UIViewControllerRepresentable {
    @Binding var images: [UIImage]
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: AppImagePicker
        init(_ parent: AppImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage { parent.images.append(image) }
            parent.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.dismiss() }
    }
}
