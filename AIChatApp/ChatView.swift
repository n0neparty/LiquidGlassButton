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
                    _ = try await APIService.shared.sendMessage(
                        model: model,
                        message: "You are in deep thinking mode. Think carefully before answering. Reply only '1337' to confirm.",
                        chatId: chatId,
                        image: nil
                    )
                }

                let response = try await APIService.shared.sendMessage(
                    model: model, message: userMsg, chatId: chatId, image: img
                )
                
                if let id = response.resolvedChatId { chatId = id }
                
                if let err = response.error {
                    messages.append(ChatMessage(role: .error, text: err))
                } else if let text = response.text {
                    let cleanedText = cleanThinkingTags(text)
                    await streamWords(cleanedText)
                }
            } catch {
                messages.append(ChatMessage(role: .error, text: error.localizedDescription))
            }
            isLoading = false
        }
    }

    /// Улучшенная очистка <think>...</think>
    private func cleanThinkingTags(_ text: String) -> String {
        var result = text
        
        if let thinkEndRange = result.range(of: "</think>", options: .caseInsensitive) {
            result = String(result[thinkEndRange.upperBound...])
        }
        
        result = result
            .replacingOccurrences(of: "1337", with: "")
            .replacingOccurrences(of: "-----", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Убираем пустые строки в начале
        let lines = result.components(separatedBy: .newlines)
        let cleanedLines = lines.drop(while: { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
        
        result = cleanedLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        
        return result
    }

    @MainActor
    private func streamWords(_ text: String) async {
        guard !text.isEmpty else { return }
        
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

// MARK: - Message Bubble (исправленный)
struct MessageBubble: View {
    let message: ChatMessage
    let providerColor: Color
    var ds: DebugSettings { DebugSettings.shared }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Левый отступ
            if message.role == .user {
                Spacer(minLength: 60)
            } else {
                Spacer(minLength: 12)
            }
            
            // Сообщение
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                if let image = message.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 180, height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: ds.messageBubbleCornerRadius, style: .continuous))
                }
                
                if !message.text.isEmpty {
                    Group {
                        if message.role == .user {
                            Text(message.text)
                                .font(.system(size: ds.messageTextSize))
                                .foregroundColor(.primary)
                                .lineSpacing(0)
                                .multilineTextAlignment(.trailing)
                        } else {
                            MarkdownText(text: message.text, 
                                         fontSize: ds.messageTextSize, 
                                         isError: message.role == .error)
                                .lineSpacing(2)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .padding(.horizontal, ds.messageBubbleHorizontalPadding)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: ds.messageBubbleCornerRadius, style: .continuous)
                            .fill(message.role == .ai ? Color(white: 0.15) : Color.clear)  // Тёмный фон для AI
                            .overlay(
                                message.role == .ai
                                    ? RoundedRectangle(cornerRadius: ds.messageBubbleCornerRadius, style: .continuous)
                                        .fill(providerColor.opacity(0.08))
                                    : nil
                            )
                    )
                    .background(
                        message.role != .ai
                            ? AnyShapeStyle(.ultraThinMaterial)
                            : AnyShapeStyle(Color.clear),
                        in: RoundedRectangle(cornerRadius: ds.messageBubbleCornerRadius, style: .continuous)
                    )
                    .frame(maxWidth: message.role == .ai ? 320 : .infinity, alignment: message.role == .user ? .trailing : .leading)
                }
            }
            
            // Правый отступ
            if message.role == .user {
                Spacer(minLength: 12)
            } else {
                Spacer(minLength: 60)
            }
        }
        .padding(.horizontal, 8)
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

// MARK: - Markdown Text
struct MarkdownText: View {
    let text: String
    let fontSize: CGFloat
    let isError: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(parseBlocks(text).enumerated()), id: \.offset) { _, block in
                blockView(block)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func blockView(_ block: MDBlock) -> some View {
        switch block {
        case .h1(let t):
            Text(t)
                .font(.system(size: fontSize + 8, weight: .bold))
                .foregroundStyle(isError ? .red : .white)
        case .h2(let t):
            Text(t)
                .font(.system(size: fontSize + 5, weight: .bold))
                .foregroundStyle(isError ? .red : .white)
        case .h3(let t):
            HStack(spacing: 6) {
                Circle().fill(Color.white.opacity(0.7)).frame(width: 5, height: 5)
                Text(t)
                    .font(.system(size: fontSize + 2, weight: .semibold))
                    .foregroundStyle(isError ? .red : .white)
            }
        case .bullet(let t):
            HStack(alignment: .top, spacing: 8) {
                Text("•").font(.system(size: fontSize)).foregroundStyle(.white.opacity(0.7))
                inlineText(t)
            }
        case .code(let t):
            Text(t)
                .font(.system(size: fontSize - 1, design: .monospaced))
                .foregroundStyle(.green.opacity(0.9))
                .padding(8)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 6))
        case .paragraph(let t):
            inlineText(t)
        case .divider:
            Divider().background(Color.white.opacity(0.2))
        }
    }

    @ViewBuilder
    private func inlineText(_ raw: String) -> some View {
        if let attr = try? AttributedString(markdown: raw, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            Text(attr)
                .font(.system(size: fontSize, weight: .regular))
                .foregroundStyle(isError ? .red : .white)
                .tint(.cyan)
        } else {
            Text(raw)
                .font(.system(size: fontSize, weight: .regular))
                .foregroundStyle(isError ? .red : .white)
        }
    }

    private func parseBlocks(_ input: String) -> [MDBlock] {
        let lines = input.components(separatedBy: "\n")
        var blocks: [MDBlock] = []
        var codeBuffer: [String] = []
        var inCode = false

        for line in lines {
            if line.hasPrefix("```") {
                if inCode {
                    blocks.append(.code(codeBuffer.joined(separator: "\n")))
                    codeBuffer = []
                    inCode = false
                } else {
                    inCode = true
                }
                continue
            }
            if inCode { codeBuffer.append(line); continue }

            if line.hasPrefix("### ") {
                blocks.append(.h3(String(line.dropFirst(4))))
            } else if line.hasPrefix("## ") {
                blocks.append(.h2(String(line.dropFirst(3))))
            } else if line.hasPrefix("# ") {
                blocks.append(.h1(String(line.dropFirst(2))))
            } else if line.hasPrefix("- ") || line.hasPrefix("* ") {
                blocks.append(.bullet(String(line.dropFirst(2))))
            } else if line.trimmingCharacters(in: .whitespaces) == "---" || line.trimmingCharacters(in: .whitespaces) == "***" {
                blocks.append(.divider)
            } else if line.trimmingCharacters(in: .whitespaces).isEmpty {
                // skip empty lines
            } else {
                blocks.append(.paragraph(line))
            }
        }
        return blocks
    }
}

enum MDBlock {
    case h1(String), h2(String), h3(String)
    case bullet(String)
    case code(String)
    case paragraph(String)
    case divider
}
