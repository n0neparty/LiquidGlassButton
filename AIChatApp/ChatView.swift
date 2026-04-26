import SwiftUI
import WebKit

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

                let isMathRelated = ["угол", "треугольник", "формул", "математик", "геометр", "физик", "°", "\\("].contains { userMsg.lowercased().contains($0) }

                let finalMessage = isMathRelated 
                    ? "Используй KaTeX: \\( ... \\) для inline, \\[ ... \\] для блоков. \\angle для углов, \\triangle для треугольника.\n\n\(userMsg)"
                    : userMsg

                let response = try await APIService.shared.sendMessage(
                    model: model, message: finalMessage, chatId: chatId, image: img
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
        if let end = result.range(of: "</think>", options: .caseInsensitive) {
            result = String(result[end.upperBound...])
        }
        return result
            .replacingOccurrences(of: "1337", with: "")
            .replacingOccurrences(of: "-----", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
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
            if message.role == .user { Spacer(minLength: 60) } else { Spacer(minLength: 12) }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 8) {
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
                            KaTeXMarkdownText(text: message.text)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(message.role == .ai ? Color(white: 0.14).cornerRadius(14) : Color.clear)
                }
            }
            .frame(maxWidth: message.role == .ai ? 350 : .infinity, alignment: message.role == .user ? .trailing : .leading)
            
            if message.role == .user { Spacer(minLength: 12) } else { Spacer(minLength: 60) }
        }
        .padding(.horizontal, 8)
    }
}

// MARK: - KaTeX Markdown
struct KaTeXMarkdownText: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(splitContent(text), id: \.self) { part in
                if part.isMath {
                    KaTeXView(latex: part.content)
                } else {
                    Text(part.content)
                        .font(.system(size: 17))
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func splitContent(_ input: String) -> [ContentPart] {
        input.components(separatedBy: .newlines).map { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let isMath = trimmed.contains("\\(") || trimmed.contains("\\[") || 
                        trimmed.contains("$$") || trimmed.contains("\\angle") || 
                        trimmed.contains("\\triangle") || trimmed.contains("^\\circ")
            return ContentPart(content: line, isMath: isMath && !trimmed.isEmpty)
        }
    }
}

struct ContentPart: Hashable {
    let content: String
    let isMath: Bool
}

// MARK: - KaTeX WebView
struct KaTeXView: UIViewRepresentable {
    let latex: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.backgroundColor = .clear
        webView.isOpaque = false
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false

        let safeLatex = latex.replacingOccurrences(of: "`", with: "\\`")
        
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/katex.min.css">
            <script src="https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/katex.min.js"></script>
            <style>
                body { margin: 0; padding: 8px 0; background: transparent; color: white; }
                .katex { font-size: 1.05em; }
            </style>
        </head>
        <body>
            <div id="math"></div>
            <script>
                katex.render(`\(safeLatex)`, document.getElementById('math'), {
                    throwOnError: false,
                    displayMode: true
                });
            </script>
        </body>
        </html>
        """
        
        webView.loadHTMLString(html, baseURL: nil)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

// MARK: - WaveLoadingAnimation
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

// MARK: - AppImagePicker
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
