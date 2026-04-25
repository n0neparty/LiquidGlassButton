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
                messageList
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
        let userMsg = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userMsg.isEmpty else { return }
        let img = selectedImages.first
        let useThinking = thinkingMode
        inputText = ""
        selectedImages = []
        messages.append(ChatMessage(role: .user, text: userMsg, image: img))
        isLoading = true

        Task {
            do {
                if useThinking {
                    let tr = try await APIService.shared.sendMessage(
                        model: model,
                        message: "Think step by step. If ready, respond: 1337",
                        chatId: chatId,
                        image: nil
                    )
                    if let id = tr.resolvedChatId { chatId = id }
                }
                let response = try await APIService.shared.sendMessage(
                    model: model, message: userMsg, chatId: chatId, image: img
                )
                if let id = response.resolvedChatId { chatId = id }
                if let err = response.error {
                    messages.append(ChatMessage(role: .error, text: err))
                } else if let text = response.text {
                    await streamWords(text)
                }
            } catch {
                messages.append(ChatMessage(role: .error, text: error.localizedDescription))
            }
            isLoading = false
        }
    }

    @MainActor
    private func streamWords(_ text: String) async {
        let words = text.components(separatedBy: " ")
        isStreaming = true
        streamingText = ""
        for (i, word) in words.enumerated() {
            try? await Task.sleep(nanoseconds: 25_000_000)
            streamingText += (i == 0 ? "" : " ") + word
        }
        messages.append(ChatMessage(role: .ai, text: text))
        streamingText = ""
        isStreaming = false
    }
}

// MARK: - Wave Loading Animation
struct WaveLoadingAnimation: View {
    let color: Color
    @State private var animating = false
    private let barCount = 5
    private let barWidth: CGFloat = 4
    private let maxHeight: CGFloat = 22
    private let minHeight: CGFloat = 5

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<barCount, id: \.self) { i in
                RoundedRectangle(cornerRadius: barWidth / 2)
                    .fill(color)
                    .frame(width: barWidth, height: animating ? maxHeight : minHeight)
                    .animation(
                        .easeInOut(duration: 0.45)
                        .repeatForever(autoreverses: true)
                        .delay(Double(i) * 0.1),
                        value: animating
                    )
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .onAppear { animating = true }
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
                if let image = message.image {
                    Image(uiImage: image)
                        .resizable().scaledToFill()
                        .frame(width: 180, height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: ds.messageBubbleCornerRadius, style: .continuous))
                }
                if !message.text.isEmpty {
                    Text(message.text)
                        .font(.system(size: ds.messageTextSize, weight: .regular))
                        .foregroundStyle(message.role == .error ? .red : .white)
                        .padding(.horizontal, ds.messageBubbleHorizontalPadding)
                        .padding(.vertical, ds.messageBubbleVerticalPadding)
                        .background(
                            message.role == .ai
                                ? AnyShapeStyle(Color(white: 0.12))
                                : AnyShapeStyle(.ultraThinMaterial),
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
