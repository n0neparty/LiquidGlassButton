import SwiftUI

// MARK: - Liquid Glass modifier
struct LiquidGlass: ViewModifier {
    var color: Color = .white
    var radius: CGFloat = 16
    var intensity: CGFloat = 0.12

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(color.opacity(intensity))
                    // Top shimmer
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(LinearGradient(
                            colors: [.white.opacity(0.18), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                    // Border
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(0.35), color.opacity(0.2), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.8
                        )
                }
            }
    }
}

extension View {
    func liquidGlass(color: Color = .white, radius: CGFloat = 16, intensity: CGFloat = 0.12) -> some View {
        modifier(LiquidGlass(color: color, radius: radius, intensity: intensity))
    }
}

// MARK: - HomeView
struct HomeView: View {
    @State private var selectedProvider = ALL_PROVIDERS[0]
    @State private var selectedModel: AIModel = ALL_PROVIDERS[0].models[0]
    @State private var inputText = ""
    @State private var navigateToChat = false
    @FocusState private var inputFocused: Bool

    let suggestions = [
        ("Tell me", "something fascinating"),
        ("Write", "professionally"),
        ("Plan", "a trip"),
        ("Explain", "like I'm 5"),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                // Ambient glow behind everything
                RadialGradient(
                    colors: [selectedProvider.color.opacity(0.22), .clear],
                    center: .init(x: 0.5, y: 0.25),
                    startRadius: 0,
                    endRadius: 420
                )
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.6), value: selectedProvider.id)

                VStack(spacing: 0) {
                    topBar
                    providerPicker.padding(.top, 10)
                    modelPicker.padding(.top, 8)
                    Spacer()
                    centerTitle
                    Spacer()
                    suggestionChips
                    inputBar.padding(.bottom, 8)
                }
            }
            .navigationDestination(isPresented: $navigateToChat) {
                ChatView(provider: selectedProvider, model: selectedModel, initialMessage: inputText)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: Top Bar
    var topBar: some View {
        HStack(spacing: 10) {
            // Settings
            Button { } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(width: 38, height: 38)
                    .liquidGlass(radius: 12)
            }

            // History
            Button { } label: {
                Image(systemName: "bubble.left")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(width: 38, height: 38)
                    .liquidGlass(radius: 12)
            }

            Spacer()

            // Current model pill
            HStack(spacing: 6) {
                Image(systemName: selectedProvider.icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(selectedProvider.color)
                Text(selectedModel.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                if let badge = selectedModel.badge {
                    Text(badge)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(selectedProvider.color)
                        .padding(.horizontal, 5).padding(.vertical, 2)
                        .background(selectedProvider.color.opacity(0.2), in: Capsule())
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            .liquidGlass(color: selectedProvider.color, radius: 20, intensity: 0.1)
            .animation(.spring(response: 0.3), value: selectedModel.id)

            Spacer()

            // New chat
            Button { inputText = ""; navigateToChat = true } label: {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(width: 38, height: 38)
                    .liquidGlass(color: selectedProvider.color, radius: 12, intensity: 0.15)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
    }

    // MARK: Provider Picker
    var providerPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ALL_PROVIDERS) { provider in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            selectedProvider = provider
                            selectedModel = provider.models[0]
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: provider.icon)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(selectedProvider.id == provider.id ? provider.color : .white.opacity(0.55))
                            Text(provider.name)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(selectedProvider.id == provider.id ? .white : .white.opacity(0.55))
                        }
                        .padding(.horizontal, 13).padding(.vertical, 8)
                        .liquidGlass(
                            color: selectedProvider.id == provider.id ? provider.color : .white,
                            radius: 14,
                            intensity: selectedProvider.id == provider.id ? 0.2 : 0.06
                        )
                        .overlay {
                            if selectedProvider.id == provider.id {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(provider.color.opacity(0.5), lineWidth: 1)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
        }
    }

    // MARK: Model Picker
    var modelPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(selectedProvider.models) { model in
                    Button {
                        withAnimation(.spring(response: 0.25)) { selectedModel = model }
                    } label: {
                        HStack(spacing: 5) {
                            Text(model.name)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(selectedModel.id == model.id ? .white : .white.opacity(0.45))
                            if let badge = model.badge {
                                Text(badge)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(selectedProvider.color)
                            }
                        }
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .liquidGlass(
                            color: selectedModel.id == model.id ? selectedProvider.color : .white,
                            radius: 11,
                            intensity: selectedModel.id == model.id ? 0.18 : 0.05
                        )
                        .overlay {
                            if selectedModel.id == model.id {
                                RoundedRectangle(cornerRadius: 11, style: .continuous)
                                    .strokeBorder(selectedProvider.color.opacity(0.45), lineWidth: 0.8)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
        }
    }

    // MARK: Center Title
    var centerTitle: some View {
        VStack(spacing: 14) {
            Text("Meet \(selectedProvider.name)")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text("Free AI at your fingertips.\nNo account required.")
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.4))
                .multilineTextAlignment(.center)
                .lineSpacing(5)
        }
        .padding(.horizontal, 32)
        .animation(.none, value: selectedProvider.id)
    }

    // MARK: Suggestion Chips
    var suggestionChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(suggestions, id: \.0) { s in
                    Button {
                        inputText = "\(s.0) \(s.1)"
                        navigateToChat = true
                    } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(s.0)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                            Text(s.1)
                                .font(.system(size: 13))
                                .foregroundStyle(.white.opacity(0.45))
                        }
                        .padding(.horizontal, 14).padding(.vertical, 12)
                        .liquidGlass(radius: 16, intensity: 0.07)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
        }
        .padding(.bottom, 12)
    }

    // MARK: Input Bar
    var inputBar: some View {
        HStack(spacing: 10) {
            Button { } label: {
                Image(systemName: "plus")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 38, height: 38)
                    .liquidGlass(radius: 19)
            }
            Button { } label: {
                Image(systemName: "lightbulb")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 38, height: 38)
                    .liquidGlass(radius: 19)
            }

            TextField("Ask anything", text: $inputText)
                .font(.system(size: 16))
                .foregroundStyle(.white)
                .tint(selectedProvider.color)
                .focused($inputFocused)
                .submitLabel(.send)
                .onSubmit { if !inputText.isEmpty { navigateToChat = true } }
                .padding(.horizontal, 16).padding(.vertical, 11)
                .liquidGlass(radius: 22, intensity: 0.08)

            Button {
                guard !inputText.isEmpty else { return }
                navigateToChat = true
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(inputText.isEmpty ? .white.opacity(0.3) : .black)
                    .frame(width: 38, height: 38)
                    .background {
                        if inputText.isEmpty {
                            Circle().fill(.white.opacity(0.08))
                        } else {
                            Circle().fill(Color.white)
                            Circle().fill(LinearGradient(
                                colors: [.white, selectedProvider.color.opacity(0.3)],
                                startPoint: .top, endPoint: .bottom
                            ))
                        }
                    }
            }
            .disabled(inputText.isEmpty)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
    }
}
