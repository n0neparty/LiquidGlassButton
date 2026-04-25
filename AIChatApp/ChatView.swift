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
                        message: "You are in deep thinking mode. Think carefully before answering. Reply only '1337' to confirm.",
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
                    let cleaned = text
                        .replacingOccurrences(of: "1337", with: "")
                        .replacingOccurrences(of: "-----", with: "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    await streamWords(cleaned)
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
                    MarkdownText(text: message.text, fontSize: ds.messageTextSize, isError: message.role == .error)
                        .padding(.horizontal, ds.messageBubbleHorizontalPadding)
                        .padding(.vertical, ds.messageBubbleVerticalPadding)
                        .background(
                            RoundedRectangle(cornerRadius: ds.messageBubbleCornerRadius, style: .continuous)
                                .fill(message.role == .ai ? Color(white: 0.05) : Color.clear)
                        )
                        .background(
                            message.role != .ai
                                ? AnyShapeStyle(.ultraThinMaterial)
                                : AnyShapeStyle(Color.clear),
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

// MARK: - Markdown Text
struct MarkdownText: View {
    let text: String
    let fontSize: CGFloat
    let isError: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(parseBlocks(LaTeXConverter.convert(text)).enumerated()), id: \.offset) { _, block in
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
        if let attr = try? AttributedString(markdown: raw, options: .init(interpretedSyntax: .inlinesOnlyPreservingWhitespace)) {
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
                } else { inCode = true }
                continue
            }
            if inCode { codeBuffer.append(line); continue }
            if line.hasPrefix("### ")      { blocks.append(.h3(String(line.dropFirst(4)))) }
            else if line.hasPrefix("## ")  { blocks.append(.h2(String(line.dropFirst(3)))) }
            else if line.hasPrefix("# ")   { blocks.append(.h1(String(line.dropFirst(2)))) }
            else if line.hasPrefix("- ") || line.hasPrefix("* ") { blocks.append(.bullet(String(line.dropFirst(2)))) }
            else if line.trimmingCharacters(in: .whitespaces) == "---" { blocks.append(.divider) }
            else if !line.trimmingCharacters(in: .whitespaces).isEmpty { blocks.append(.paragraph(line)) }
        }
        return blocks
    }
}

enum MDBlock {
    case h1(String), h2(String), h3(String)
    case bullet(String), code(String), paragraph(String), divider
}

// MARK: - LaTeX Converter
struct LaTeXConverter {
    static func convert(_ input: String) -> String {
        var s = input
        // Strip math delimiters
        s = s.replacingOccurrences(of: "\\[", with: "")
        s = s.replacingOccurrences(of: "\\]", with: "")
        s = s.replacingOccurrences(of: "$$", with: "")
        // Inline $...$ — unwrap content, then strip lone $
        s = s.replacingOccurrences(of: #"\$([^$\n]+)\$"#, with: "$1", options: .regularExpression)
        s = s.replacingOccurrences(of: "$", with: "")
        // Fractions
        s = replaceFrac(s)
        // Commands with braces
        s = replaceCmd(s, cmd: "sqrt",    open: "√(",  close: ")")
        s = replaceCmd(s, cmd: "text",    open: "",    close: "")
        s = replaceCmd(s, cmd: "mathrm",  open: "",    close: "")
        s = replaceCmd(s, cmd: "mathbf",  open: "",    close: "")
        s = replaceCmd(s, cmd: "mathit",  open: "",    close: "")
        s = replaceCmd(s, cmd: "mathbb",  open: "",    close: "")
        s = replaceCmd(s, cmd: "left",    open: "",    close: "")
        s = replaceCmd(s, cmd: "right",   open: "",    close: "")
        // Superscripts & subscripts
        s = replaceSuperscript(s)
        s = replaceSubscript(s)
        // overline, vec, widehat
        s = s.replacingOccurrences(of: #"\\overline\{([^}]+)\}"#,  with: "$1\u{0305}", options: .regularExpression)
        s = s.replacingOccurrences(of: #"\\vec\{([^}]+)\}"#,       with: "$1\u{20D7}", options: .regularExpression)
        s = s.replacingOccurrences(of: #"\\widehat\{([^}]+)\}"#,   with: "$1\u{0302}", options: .regularExpression)
        s = s.replacingOccurrences(of: #"\\widetilde\{([^}]+)\}"#, with: "$1\u{0303}", options: .regularExpression)
        // All symbol replacements
        let replacements: [(String, String)] = [
            // Greek lowercase
            ("\\alpha","α"),("\\beta","β"),("\\gamma","γ"),("\\delta","δ"),
            ("\\epsilon","ε"),("\\varepsilon","ε"),("\\zeta","ζ"),("\\eta","η"),
            ("\\theta","θ"),("\\vartheta","θ"),("\\iota","ι"),("\\kappa","κ"),
            ("\\lambda","λ"),("\\mu","μ"),("\\nu","ν"),("\\xi","ξ"),
            ("\\pi","π"),("\\varpi","π"),("\\rho","ρ"),("\\varrho","ρ"),
            ("\\sigma","σ"),("\\varsigma","ς"),("\\tau","τ"),("\\upsilon","υ"),
            ("\\phi","φ"),("\\varphi","φ"),("\\chi","χ"),("\\psi","ψ"),("\\omega","ω"),
            // Greek uppercase
            ("\\Gamma","Γ"),("\\Delta","Δ"),("\\Theta","Θ"),("\\Lambda","Λ"),
            ("\\Xi","Ξ"),("\\Pi","Π"),("\\Sigma","Σ"),("\\Upsilon","Υ"),
            ("\\Phi","Φ"),("\\Psi","Ψ"),("\\Omega","Ω"),
            // Geometry
            ("\\triangle","△"),("\\angle","∠"),("\\perp","⊥"),("\\parallel","∥"),
            ("\\measuredangle","∡"),("\\sphericalangle","∢"),
            // Relations
            ("\\sim","∼"),("\\cong","≅"),("\\approx","≈"),("\\neq","≠"),("\\ne","≠"),
            ("\\equiv","≡"),("\\leq","≤"),("\\le","≤"),("\\geq","≥"),("\\ge","≥"),
            ("\\ll","≪"),("\\gg","≫"),("\\prec","≺"),("\\succ","≻"),
            ("\\propto","∝"),("\\asymp","≍"),
            // Arithmetic
            ("\\infty","∞"),("\\pm","±"),("\\mp","∓"),("\\times","×"),("\\div","÷"),
            ("\\cdot","·"),("\\circ","∘"),("\\bullet","•"),("\\oplus","⊕"),("\\otimes","⊗"),
            // Sets
            ("\\in","∈"),("\\notin","∉"),("\\ni","∋"),
            ("\\subset","⊂"),("\\subseteq","⊆"),("\\nsubseteq","⊄"),
            ("\\supset","⊃"),("\\supseteq","⊇"),
            ("\\cup","∪"),("\\cap","∩"),("\\emptyset","∅"),("\\varnothing","∅"),
            ("\\setminus","∖"),
            // Logic
            ("\\forall","∀"),("\\exists","∃"),("\\nexists","∄"),
            ("\\neg","¬"),("\\lnot","¬"),("\\land","∧"),("\\lor","∨"),
            // Arrows
            ("\\rightarrow","→"),("\\to","→"),("\\leftarrow","←"),("\\gets","←"),
            ("\\Rightarrow","⇒"),("\\Leftarrow","⇐"),
            ("\\leftrightarrow","↔"),("\\Leftrightarrow","⇔"),
            ("\\uparrow","↑"),("\\downarrow","↓"),("\\updownarrow","↕"),
            ("\\nearrow","↗"),("\\searrow","↘"),("\\swarrow","↙"),("\\nwarrow","↖"),
            ("\\mapsto","↦"),("\\longmapsto","⟼"),
            // Calculus
            ("\\sum","∑"),("\\prod","∏"),("\\int","∫"),("\\oint","∮"),
            ("\\iint","∬"),("\\iiint","∭"),
            ("\\partial","∂"),("\\nabla","∇"),("\\grad","∇"),
            // Misc
            ("\\ldots","…"),("\\cdots","⋯"),("\\vdots","⋮"),("\\ddots","⋱"),
            ("\\lfloor","⌊"),("\\rfloor","⌋"),("\\lceil","⌈"),("\\rceil","⌉"),
            ("\\langle","⟨"),("\\rangle","⟩"),
            ("\\|","‖"),("\\{","{"),("\\}","}"),
            ("^\\circ","°"),("\\degree","°"),
            ("\\therefore","∴"),("\\because","∵"),
            ("\\sqrt","√"),("\\hbar","ℏ"),("\\ell","ℓ"),
            ("\\Re","ℜ"),("\\Im","ℑ"),("\\wp","℘"),
            ("\\aleph","ℵ"),("\\beth","ℶ"),
            ("\\top","⊤"),("\\bot","⊥"),
            ("\\vdash","⊢"),("\\models","⊨"),
            ("\\overbrace",""),("\\underbrace",""),
        ]
        for (latex, unicode) in replacements {
            s = s.replacingOccurrences(of: latex, with: unicode)
        }
        // Remove remaining \commands
        s = s.replacingOccurrences(of: #"\\\w+"#, with: "", options: .regularExpression)
        // Clean leftover braces
        s = s.replacingOccurrences(of: "{", with: "")
        s = s.replacingOccurrences(of: "}", with: "")
        return s
    }

    private static func replaceFrac(_ s: String) -> String {
        var result = s
        let pattern = #"\\frac\{([^}]*)\}\{([^}]*)\}"#
        while let range = result.range(of: pattern, options: .regularExpression) {
            let match = String(result[range])
            if let r = match.range(of: #"\{([^}]*)\}\{([^}]*)\}"#, options: .regularExpression) {
                let inner = String(match[r]).dropFirst().dropLast()
                let split = inner.components(separatedBy: "}{")
                if split.count == 2 {
                    result = result.replacingCharacters(in: range, with: "(\(split[0])/\(split[1]))")
                    continue
                }
            }
            break
        }
        return result
    }

    private static func replaceCmd(_ s: String, cmd: String, open o: String, close c: String) -> String {
        var r = s
        let pattern = "\\\\\(cmd)\\{([^}]*)\\}"
        r = r.replacingOccurrences(of: pattern, with: "\(o)$1\(c)", options: .regularExpression)
        return r
    }

    private static func replaceSuperscript(_ s: String) -> String {
        let map: [Character: String] = [
            "0":"⁰","1":"¹","2":"²","3":"³","4":"⁴","5":"⁵","6":"⁶","7":"⁷","8":"⁸","9":"⁹",
            "n":"ⁿ","i":"ⁱ","a":"ᵃ","b":"ᵇ","c":"ᶜ","d":"ᵈ","e":"ᵉ","f":"ᶠ","g":"ᵍ",
            "h":"ʰ","j":"ʲ","k":"ᵏ","l":"ˡ","m":"ᵐ","o":"ᵒ","p":"ᵖ","r":"ʳ","s":"ˢ",
            "t":"ᵗ","u":"ᵘ","v":"ᵛ","w":"ʷ","x":"ˣ","y":"ʸ","z":"ᶻ","+":"⁺","-":"⁻"
        ]
        var result = s
        result = result.replacingOccurrences(of: #"\^\{([^}]+)\}"#, with: { m in
            m.dropFirst(2).dropLast().map { map[$0] ?? String($0) }.joined()
        }, options: .regularExpression)
        result = result.replacingOccurrences(of: #"\^([0-9a-zA-Z])"#, with: { m in
            map[m.last!] ?? String(m.last!)
        }, options: .regularExpression)
        return result
    }

    private static func replaceSubscript(_ s: String) -> String {
        let map: [Character: String] = [
            "0":"₀","1":"₁","2":"₂","3":"₃","4":"₄","5":"₅","6":"₆","7":"₇","8":"₈","9":"₉",
            "a":"ₐ","e":"ₑ","o":"ₒ","x":"ₓ","n":"ₙ","i":"ᵢ","j":"ⱼ","k":"ₖ","l":"ₗ",
            "m":"ₘ","p":"ₚ","r":"ᵣ","s":"ₛ","t":"ₜ","u":"ᵤ","v":"ᵥ","+":"₊","-":"₋"
        ]
        var result = s
        result = result.replacingOccurrences(of: #"_\{([^}]+)\}"#, with: { m in
            m.dropFirst(2).dropLast().map { map[$0] ?? String($0) }.joined()
        }, options: .regularExpression)
        result = result.replacingOccurrences(of: #"_([0-9a-zA-Z])"#, with: { m in
            map[m.last!] ?? String(m.last!)
        }, options: .regularExpression)
        return result
    }
}

// MARK: - String regex helper
private extension String {
    func replacingOccurrences(of pattern: String, with transform: (String) -> String, options: String.CompareOptions) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return self }
        let results = regex.matches(in: self, range: NSRange(self.startIndex..., in: self))
        var result = self
        for match in results.reversed() {
            guard let range = Range(match.range, in: self),
                  let rRange = Range(match.range, in: result) else { continue }
            result = result.replacingCharacters(in: rRange, with: transform(String(self[range])))
        }
        return result
    }
}
