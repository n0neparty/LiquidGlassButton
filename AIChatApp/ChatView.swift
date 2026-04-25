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
                        MessageBubble(message: ChatMessage(role: .ai, text: streamingText), providerColor: provider.color)
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

                // Сильная инструкция для нейросети, чтобы она всегда использовала правильный LaTeX
                let mathPrompt = """
                Всегда используй правильный KaTeX / LaTeX синтаксис для математики:
                - Inline: \\( формула \\)
                - Блок: \\[ формула \\] или $$ формула $$
                Для углов: \\angle, для треугольника: \\triangle, для градусов: ^\\circ
                Пример: \\angle BDT = 80^\\circ
                """

                let response = try await APIService.shared.sendMessage(
                    model: model,
                    message: mathPrompt + "\n\n" + userMsg,
                    chatId: chatId,
                    image: img
                )
                
                if let id = response.resolvedChatId { chatId = id }
                
                if let err = response.error {
                    messages.append(ChatMessage(role: .error, text: err))
                } else if let text = response.text {
                    let cleaned = cleanThinkingTags(text)
                    await streamWords(cleaned)
                }
            } catch {
                messages.append(ChatMessage(role: .error, text: error.localizedDescription))
            }
            isLoading = false
        }
    }

    private func cleanThinkingTags(_ text: String) -> String {
        var result = text
        if let endRange = result.range(of: "</think>", options: .caseInsensitive) {
            result = String(result[endRange.upperBound...])
        }
        result = result
            .replacingOccurrences(of: "1337", with: "")
            .replacingOccurrences(of: "-----", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        let lines = result.components(separatedBy: .newlines)
        let cleanedLines = lines.drop(while: { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
        return cleanedLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
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

// MARK: - Message Bubble
struct MessageBubble: View {
    let message: ChatMessage
    let providerColor: Color
    var ds: DebugSettings { DebugSettings.shared }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            if message.role == .user {
                Spacer(minLength: 60)
            } else {
                Spacer(minLength: 12)
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 6) {
                if let image = message.image {
                    Image(uiImage: image)
                        .resizable().scaledToFill()
                        .frame(width: 180, height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                if !message.text.isEmpty {
                    Group {
                        if message.role == .user {
                            Text(message.text)
                                .font(.system(size: ds.messageTextSize))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.trailing)
                        } else {
                            MathMarkdownText(text: message.text, fontSize: ds.messageTextSize)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(
                        message.role == .ai 
                        ? Color(white: 0.14).cornerRadius(14)
                        : Color.clear
                    )
                }
            }
            .frame(maxWidth: message.role == .ai ? 350 : .infinity, 
                   alignment: message.role == .user ? .trailing : .leading)
            
            if message.role == .user {
                Spacer(minLength: 12)
            } else {
                Spacer(minLength: 60)
            }
        }
        .padding(.horizontal, 8)
    }
}

// MARK: - Улучшенный рендер математики (обрабатывает почти всё)
struct MathMarkdownText: View {
    let text: String
    let fontSize: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(parseMathBlocks(text), id: \.self) { part in
                if part.isMath {
                    Text(part.content)
                        .font(.system(size: fontSize + 2, design: .monospaced))
                        .foregroundColor(.cyan)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.085))
                        .cornerRadius(10)
                } else {
                    Text(part.content)
                        .font(.system(size: fontSize))
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func parseMathBlocks(_ input: String) -> [MathPart] {
        var parts: [MathPart] = []
        var remaining = input
        
        let regexPatterns = [
            #"\\\[(.*?)\\\]"#,      // \[ ... \]
            #"\$\$(.*?)\$\$"#,      // $$ ... $$
            #"\\\((.*?)\\\)"#       // \( ... \)
        ]
        
        while !remaining.isEmpty {
            var matched = false
            for pattern in regexPatterns {
                if let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]),
                   let match = regex.firstMatch(in: remaining, range: NSRange(remaining.startIndex..., in: remaining)) {
                    
                    let beforeRange = NSRange(location: 0, length: match.range.location)
                    if let before = Range(beforeRange, in: remaining), !before.isEmpty {
                        parts.append(MathPart(content: String(remaining[before]).trimmingCharacters(in: .whitespacesAndNewlines), isMath: false))
                    }
                    
                    let mathRange = Range(match.range(at: 1), in: remaining)!
                    let mathContent = String(remaining[mathRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    parts.append(MathPart(content: mathContent, isMath: true))
                    
                    remaining = String(remaining[Range(match.range.upperBound..., in: remaining)!])
                    matched = true
                    break
                }
            }
            if !matched {
                parts.append(MathPart(content: remaining, isMath: false))
                break
            }
        }
        return parts
    }
}

struct MathPart: Hashable {
    let content: String
    let isMath: Bool
}

// MARK: - WaveLoadingAnimation, AppImagePicker (оставлены как были)
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
                    .animation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true).delay(Double(i) * 0.1), value: animating)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .onAppear { animating = true }
    }
}

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
