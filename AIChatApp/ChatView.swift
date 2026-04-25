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
                if isLoadin) }
                inputBar
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
         s() } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left").font(.system(size: 14, weight: .semibold))
                        Text("Back").font(.system(size: 16, weight: .regular))
                    }
                    .foregroundStyle(.white)
                }
            }
        }
        .navigationTitle(model.name)
        .navigationBaayMode(.inline)
        .preferredColorScheme(.dark)
        .task {
            thinkingMode = initialThinkingMode
            selectedImages = initialImages
            if !initialMessage.isEmpty { inputText = initialMessage; sendMessage() }
        }
    }

    var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: ds.messageSpacing) {
                    ForEach(messages) { msg in
                        MessageBubble(message: msg, providerColor: provider.color).id(msg.id)
                    }
                    if isStreaming && !streamingText.isEmpty {
 providerColor: provider.color)
                            .id("streaming")
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 20)
            }
            .onChange(of: messages.count) { _, _ in
                if let last = messages.last {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { proxy.scrollTo(last.id, anchor: .bottom) }
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
                     uiImage: image).resizable().scaledToFill()
                              .frame(width: 64, height: 64)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                Button { selectedImages.remove(at: index) } label: {
                                    Image(systemName: "xmark.circle.fill").font(.system(size: 20))
                                        .foregroundStyle(.white).background(Circle().fill(.black.opacity(0.6)))
                                }
     et(x: 8, y: -8)
                            }
                        }
                    }
                    .padding(.horizontal, ds.inputBarHorizontalPadding).padding(.top, 10)
                }
                .padding(.bottom, 8)
            }
            HStack(spacing: 0) {
                HStack(spacing: 6) {
                    Button { showImagePicker = true } label: {
                        Image(systemName: "plus").font(.system(size: ds.buttonIconSize, weight: .bold))
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
                 oregroundStyle(.white).tint(provider.color)
                    .focused($inputFocused).submitLabel(.send).onSubmit { sendMessage() }
                    .padding(.horizontal, 18).padding(.vertical, 13).frame(height: 44)
                    .background(Capsule().fill(.ultraThinMaterial)).layoutPriority(-1)
                Spacer().frame(width: ds.inputBarSpacing)
                if inputText.isEmpty {
                    Button { } label: {
                        Image(systemName: "arrow.s.buttonIconSize, weight: .bold))
                            .foregroundStyle(.white).frame(width: ds.buttonSize, height: ds.buttonSize)
                    }
                    .buttonStyle(.glass).buttonBorderShape(.circle).disabled(true)
                    .frame(width: ds.buttonSize, height: ds.buttonSize).layoutPriority(1)
                } else {
                    Button { sendMessage() } label: {
                        Image(systemName: "arrow.up").font(.system(size: ds.buttonIconSize, weight: .bold))
                            .foregroundStyle(.black).frame(width: ds.buttonSize, height: ds.buttonSize)
                    }
                    .buttonStyle(.plain).background(Circle().fill(.white))
                    .frame(width: ds.buttonSize, height: ds.buttonSize).layoutPriority(1)
                }
            }
            .padding(.horizontal, ds.inputBarHorizontalPadding)
            .padding(.vertical, ds.inputBarVerticalPadding).padding(.bottom, 8)
        }
        .sheet(isPresented: $showImagePicker) { AppImagePicker(images: $selectedImages) }
    }

    private func sendMessage() {
        let userMsg = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userMsg.isEmpty else { return }
        let img = selectedImages.first
        let useThinking = thinkingMode
        inputText = ""; selectedImages = []
        messages.append(ChatMessage(role: .user, text: userMsg, image: img))
        isLoading = true
        Task {
            do {
                if useThinking {
                    let tr = try await APIService.shared.sendMessage(model: model, message: "Think carefully. Reply only '1337' to confirm.", chatId: chatId, image: nil)
                    if let id = tr.resolvedChatId { chatId = id }
                }
                let response = try await APIService.shared.sendMessage(model: mode
                if let id = response.resolvedChatId { chatId = id }
                if let err = response.error {
                    messages.append(ChatMessage(role: .error, text: err))
                } else if let text = response.text {
                    let cleaned = text.replacingOccurrences(of: "1337", with: "").replacingOccurrences(of: "-----", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
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
        isStreaming = true; streamingText = ""
        for (i, word) in words.enumerated() {
            try? await Task.sleep(nanoseconds: 25_000_000)
            streamingText += (i == 0 ? "" : " ") + word
        }
        messages.append(ChatMessage(role: .ai, text: text))
        streamingText = ""; isStreaming = false
    }
}

// MARK: - Wave Loading Animation
struct WaveLoadingAnimation: View {
    let color: Color
    @State private var animating = false
    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<5, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(color).frame(width: 4, height: animating ? 22 : 5)
                    .animation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true).delay(Double(i) * 0.1), value: animating)
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
                    Image(uiImage: image).resizable().scaledToFill()
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
                            message.role != .ai ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(Color.clear),
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
    @ent(\.dismiss) var dismiss
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let p = UIImagePickerController(); p.delegate = context.coordinator; p.sourceType = .photoLibrary; return p
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: AppImage
        init(_ parent: AppImagePicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage { parent.images.append(image) }
            parent.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.dismiss() }
    }
}

// MARK: - Markdown + LaTeX Text
struct MarkdownText: View {
    let text: String
    let fontSize: CGFloat
    let isError: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                blockView(block)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var blocks: [MDBlock] { parseBlocks(convertLatex(text)) }

    @ViewBuilder
    private func blockView(_ block: MDBlock) -> some View {
        switch block {
  case .h1(let t): Text(t).font(.system(size: fontSize + 8, weight: .bold)).foregroundStyle(isError ? .red : .white)
        case .h2(let t): Text(t).font(.system(size: fontSize + 5, weight: .bold)).foregroundStyle(isError ? .red : .white)
        case .h3(let t):
            HStack(spacing: 6) {
                Circle().fill(Color.white.opacity(0.7)).frame(width: 5, height: 5)
                Text(t).font(.system(size: fontSize + 2, weight: .semibold)).foregroundStyle(isError ? .red : .white)
            }
        case .bullet(let t):
            HStack(alignment: .top, spacing: 8) {
                Text("•").font(.system(size: fontSize)).foregroundStyle(.white.opacity(0.7))
                inlineText(t)
            }
        case .code(let t):
            Text(t).font(.system(size: fontSize - 1, design: .monospaced)).foregroundStyle(.green.opacity(0.9))
                .padding(8).background(Color.white.opacity(0.06)).clipShape(RoundedRectangle(cornerRadius: 6))
        case .paragraph(let t): inlineText(t)
        case .divider: Divider().background(Color.white.opacity(0.2))
        }
    }

    @ViewBuilder
    private func inlineText(_ raw: String) -> some View {
        if let attr = try? AttributedString(markdown: raw, options: .init(interpretedSyntax: .inlinesOnly)) {
            Text(attr).font(.system(size: fontSize)).foregroundStyle(isError ? .red : .white).tint(.cyan)
        } else {
            Text(raw).font(.system(size: fontSize)).foregroundStyle(isError ? .red : .white)
        }
    }

    peBlocks(_ input: String) -> [MDBlock] {
        var blocks: [MDBlock] = []
        var codeBuf: [String] = []
        var inCode = false
        for line in input.components(separatedBy: "\n") {
            if line.hasPrefix("```") {
                if inCode { blocks.append(.code(codeBuf.joined(separator: "\n"))); codeBuf = []; inCode = false }
                else { inCode = true }
                continue
            }
            if inCode { codeBuf.append(line); continue }
            if line.hasPrefix("### ")     { blocks.append(.h3(String(line.dropFirst(4)))) }
            else if line.hasPrefix("## ") { blocks.append(.h2(String(line.dropFirst(3)))) }
            else if line.hasPrefix("# ")  { blocks.append(.h1(String(line.dropFirst(2)))) }
            else if line.hasPrefix("- ") || line.hasPrefix("* ") { blocks.append(.bullet(String(line.dropFirst(2)))) }
            else if line.trimmingCharacters(in: .whitespaces) == "---" { blocks.append(.divider) }
            else if !line.trimmingCharacters(in: .whitespaces).isEmpty { blocks.append(.paragraph(line)) }
        }
        return blocks
    }

    private func convertLatex(_ input: String) -> String {
        var s = input
        s = s.replacingOccurrences(of: "\\[", with: "").replacingOccurrences(of: "\\]", with: "")
        s = s.replacingOccurrences(of: "$$", with: "")
        if let re = try? NSRegularExpression(pattern: #"\$([^$\n]+)\$"#) {
         
        }
        s = s.replacingOccurrences(of: "$", with: "")
        s = replaceFrac(s)
        s = replaceCmd(s, cmd: "sqrt", open: "√(", close: ")")
        s = replaceCmd(s, cmd: "text", open: "", close: "")
        s = replaceCmd(s, cmd: "mathrm", open: "", close: "")
        s = replaceCmd(s, cmd: "mathbf", open: "", close: "")
        s = replacePowers(s)
        s = replaceSubs(s)
        let table: [(String, String)] = [
            ("\\alpha","α"\\epsilon","ε"),
            ("\\varepsilon","ε"),("\\zeta","ζ"),("\\eta","η"),("\\theta","θ"),("\\iota","ι"),
            ("\\kappa","κ"),("\\lambda","λ"),("\\mu","μ"),("\\nu","ν"),("\\xi","ξ"),
            ("\\pi","π"),("\\rho","ρ"),("\\sigma","σ"),("\\tau","τ"),("\\upsilon","υ"),
            ("\\phi","φ"),("\\varphi","φ"),("\\chi","χ"),("\\psi","ψ"),("\\omega","ω"),
            ("\\Gamma","Γ"),("\\Delta","Δ"),("\\Theta","Θ"),("\\Lambda","Λ"),("\\Xi","Ξ"),
            ("\\Pi","Π"),("\\Sigma","Σ"),("\\Phi","Φ"),("\\Psi","Ψ"),("\\Omega","Ω"),
            ("\\triangle","△"),("\\angle","∠"),("\\perp","⊥"),("\\parallel","∥"),
            ("\\sim","∼"),("\\cong","≅"),("\\approx","≈"),("\\neq","≠"),("\\ne","≠"),
            ("\\equiv","≡"),("\\leq","≤"),("\\le","≤"),("\\geq","≥"),("\\ge","≥"),
            ("\\ll","≪"),("\\gg","≫"),("\\infty","∞"),("\\pm","±"),("\\mp","∓"),
            ("\\times","×"),("\\div","÷"),("\\cdot","·"),("\\circ","∘"),("\\bullet","•"),
            ("\\in","∈")"\\subseteq","⊆"),
            ("\\supset","⊃"),("\\cup","∪"),("\\cap","∩"),("\\emptyset","∅"),
            ("\\forall","∀"),("\\exists","∃"),("\\neg","¬"),("\\land","∧"),("\\lor","∨"),
            ("\\rightarrow","→"),("\\to","→"),("\\leftarrow","←"),
            ("\\Rightarrow","⇒"),("\\Leftarrow","⇐"),("\\leftrightarrow","↔"),("\\Leftrightarrow","⇔"),
            ("\\uparrow","↑"),("\\downarrow","↓"),("\\mapsto","↦"),
            ("\\sum","∑"),("\\prod","∏"),("\\int","∫"),("\\oint","∮"),
            ("\\partial","∂"),("\\nabla","∇"),
            ("\\ldots","…"),("\\cdots","⋯"),("\\vdots","⋮"),("\\ddots","⋱"),
            ("\\lfloor","⌊"),("\\rfloor","⌋"),("\\lceil","⌈"),("\\rceil","⌉"),
            ("\\langle","⟨"),("\\rangle","⟩"),
            ("\\{","{"),("\\}","}"),("\\|","‖"),("^\\circ","°"),("\\degree","°"),
            ("\\therefore","∴"),("\\because","∵"),("\\propto","∝"),
            ("\\hbar","ℏ"),("\\ell","ℓ"),("\\Re","ℜ"),("\\Im","ℑ"),
        ]
        for (l, u) in table , with: u) }
        if let re = try? NSRegularExpression(pattern: #"\\overline\{([^}]+)\}"#) {
            s = re.stringByReplacingMatches(in: s, range: NSRange(s.startIndex..., in: s), withTemplate: "$1\u{0305}")
        }
        if let re = try? NSRegularExpression(pattern: #"\\vec\{([^}]+)\}"#) {
            s = re.stringByReplacingMatches(in: s, range: NSRange(s.startIndex..., in: s), withTemplate: "$1\u{20D7}")
        }
        if let re = try? NSRegularExpression(pattern: #"\\\w+"#) {
            s = re.stringByReplacingMatches(in: s, range: NSRange(s.startIndex..., in: s), withTemplate: "")
        }
        s = s.replacingOccurrences(of: "{", with: "").replacingOccurrences(of: "}", with: "")
        return s
    }

    private func replaceFrac(_ s: String) -> String {
        var result = s
        let pattern = #"\\frac\{([^}]*)\}\{([^}]*)\}"#
        while let range = result.range(of: pattern, options: .regularExpression) {
            let match = String(result[range])
            if let r = match.range(of: #"\{([^}]*)\}\{([^}]*)\}"#, options: .regularExpression) {
                let inner = String(match[r]).dropFirst().dropLast()
                let split = inner.components(separatedBy: "}{")
                if split.count == 2 { result = result.replacingCharacters(in: range, with: "(\(split[0])/\(split[1]))"); continue }
            }
            break
        }
        return result
    }

    private func replaceCmd(_ s: String, cmd: String, open o: String, close c: String) -> String {
        guard let re = try? NSRegularExpression(pattern: "\\\\\(cmd)\\{([^}]*)\\}") else { return s }
        return re.stringByReplacingMatches(in: s, range: NSRange(s.startIndex..., in: s), withTemplate: "\(o)$1\(c)")
    }

    private func replacePowers(_ s: String) -> String {
        let supMap: [String: String] = [
            "0":"\u{2070}","1":"\u{00B9}","2":"\u{00B2}","3":"\u{00B3}","4":"\u{2074}",
            "5":"\u{2075}","6":"\u{2076}","7":"\u{2077}","8":"\u{2078}","9":"\u{2079}",
            "n":"\u{207F}","i":"\u{2071}","a":"\u{1D43}","b":"\u{1D47}","c":"\u{1D9C}",
            "d":"\u{1D48}","e":"\u{1D49}","f":"\u{1DA0}","g":"\u{1D4D}","h":"\u{02B0}",
            "j":"\u{02B2}","k":"\u{1D4F}","l":"\u{02E1}","m":"\u{1D50}","o":"\u{1D52}",
            "p":"\u{1D56}","r":"\u{02B3}","s":"\u{02E2}","t":"\u{1D57}","u":"\u{1D58}",
            "v":"\u{1D5B}","w":"\u{02B7}","x":"\u{02E3}","y":"\u{02B8}","z":"\u{1DBB}",
            "+":"\u{207A}","-":"\u{207B}"
        ]
        var result = s
        if let re = try? NSRegularExpression(pattern: #"\^\{([^}]+)\}"#) {
            let matches = re.matches(in: result, range: NSRange(result.startIndex..., in: result))
            for m in matches.reversed() {
                guard let r = Range(m.range, in: result), let gr = Range(m.range(at: 1), in: result) else { continue }
                let mapped = result[gr].map { supMap[String($0)] ?? String($0) }.joined()
                result.replaceSubrange(r, with: mapped)
            }
        }
        if let re = try? NSRegularExpression(pattern: #"\^([0-9a-zA-Z])"#) {
            let matches = re.matches(in: result, range: NSRange(result.startIndex..., in: result))
            for m in matches.reversed() {
                guard let r = Range(m.range, in: result), let gr = Range(m.range(at: 1), in: result) else { continue }
                let mapped = supMap[String(result[gr])] ?? String(result[gr])
                result.replaceSubrange(r, with: mapped)
            }
        }
        return result
    }

    private func replaceSubs(_ s: String) -> String {
        let subMap: [String: String] = [
            "0":"\u{2080}","1":"\u{2081}","2":"\u{2082}","3":"\u{2083}","4":"\u{2084}",
            "5":"\u{2085}","6":"\u{2086}","7":"\u{2087}","8":"\u{2088}","9":"\u{2089}",
            "a":"\u{2090}","e":"\u{2091}","o":"\u{2092}","x":"\u{2093}","n":"\u{2099}",
            "i":"\u{1D62}","j":"\u{2C7C}","k":"\u{2096}","l":"\u{2097}","m":"\u{2098}",
            "p":"\u{209A}","r":"\u{1D63}","s":"\u{209B}","t":"\u{209C}","u":"\u{1D64}",
            "v":"\u{1D65}","+":"\u{208A}","-":"\u{208B}"
        ]
        var result = s
        if let re = try? NSRegularExpression(pattern: #"_\{([^}]+)\}"#) {
            let matches = re.matches(in: result, range: NSRange(result.startIndex..., in: result))
            for m in matches.reversed() {
                guard let r = Range(m.range, in: result), let gr = Range(m.range(at: 1), in: result) else { continue }
                let mapped = result[gr].map { subMap[String($0)] ?? String($0) }.joined()
                result.replaceSubrange(r, with: mapped)
            }
        }
        if let re = try? NSRegularExpression(pattern: #"_([0-9a-zA-Z])"#) {
            let matches = re.matches(in: result, range: NSRange(result.startIndex..., in: result))
            for m in matches.reversed() {
                guard let r = Range(m.range, in: result), let gr = Range(m.range(at: 1), in: result) else { continue }
                let mapped = subMap[String(result[gr])] ?? String(result[gr])
                result.replaceSubrange(r, with: mapped)
            }
        }
        return result
    }
}

enum MDBlock {
    case h1(String), h2(String), h3(String)
    case bullet(String), code(String), paragraph(String), divider
}
