import SwiftUI

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
                // Background
                Color.black.ignoresSafeArea()

                // Ambient glow
                RadialGradient(
                    colors: [selectedProvider.color.opacity(0.18), .clear],
                    center: .init(x: 0.5, y: 0.3),
                    startRadius: 0,
                    endRadius: 350
                )
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.5), value: selectedProvider.id)

                VStack(spacing: 0) {
                    // ── Top bar ──────────────────────────────────────────────
                    topBar

                    // ── Provider picker ──────────────────────────────────────
                    providerPicker
                        .padding(.top, 8)

                    // ── Model picker ─────────────────────────────────────────
                    modelPicker
                        .padding(.top, 6)

                    Spacer()

                    // ── Center title ─────────────────────────────────────────
                    centerTitle

                    Spacer()

                    // ── Suggestions ──────────────────────────────────────────
                    suggestionChips

                    // ── Input bar ────────────────────────────────────────────
                    inputBar
                        .padding(.bottom, 8)
                }
            }
            .navigationDestination(isPresented: $navigateToChat) {
                ChatView(provider: selectedProvider, model: selectedModel, initialMessage: inputText)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Top Bar
    var topBar: some View {
        HStack {
            Button { } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 20))
                    .foregroundStyle(.white.opacity(0.8))
            }
            Button { } label: {
                Image(systemName: "bubble.left")
                    .font(.system(size: 20))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(.leading, 4)

            Spacer()

            // Current model name
            HStack(spacing: 6) {
                Image(systemName: selectedProvider.icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(selectedProvider.color)
                Text(selectedModel.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                if let badge = selectedModel.badge {
                    Text(badge)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(selectedProvider.color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(selectedProvider.color.opacity(0.15), in: Capsule())
                }
            }

            Spacer()

            Button { } label: {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 20))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(8)
                    .background(.white.opacity(0.08), in: Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // MARK: - Provider Picker
    var providerPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ALL_PROVIDERS) { provider in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedProvider = provider
                            selectedModel = provider.models[0]
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: provider.icon)
                                .font(.system(size: 12, weight: .semibold))
                            Text(provider.name)
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundStyle(selectedProvider.id == provider.id ? .black : .white.opacity(0.7))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background {
                            if selectedProvider.id == provider.id {
                                Capsule().fill(provider.color)
                            } else {
                                Capsule().fill(.white.opacity(0.08))
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Model Picker
    var modelPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(selectedProvider.models) { model in
                    Button {
                        withAnimation(.spring(response: 0.25)) {
                            selectedModel = model
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(model.name)
                                .font(.system(size: 12, weight: .medium))
                            if let badge = model.badge {
                                Text(badge)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(selectedProvider.color)
                            }
                        }
                        .foregroundStyle(selectedModel.id == model.id ? .white : .white.opacity(0.5))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(selectedModel.id == model.id
                                      ? selectedProvider.color.opacity(0.2)
                                      : .white.opacity(0.05))
                                .overlay {
                                    if selectedModel.id == model.id {
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .strokeBorder(selectedProvider.color.opacity(0.5), lineWidth: 1)
                                    }
                                }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Center Title
    var centerTitle: some View {
        VStack(spacing: 14) {
            Text("Meet \(selectedProvider.name)")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .animation(.none, value: selectedProvider.id)

            Text("Free AI models at your fingertips.\nNo account required.")
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.45))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Suggestion Chips
    var suggestionChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(suggestions, id: \.0) { s in
                    Button {
                        inputText = "\(s.0) \(s.1)"
                        navigateToChat = true
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(s.0)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                            Text(s.1)
                                .font(.system(size: 13))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 12)
    }

    // MARK: - Input Bar
    var inputBar: some View {
        HStack(spacing: 10) {
            Button { } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 36, height: 36)
                    .background(.white.opacity(0.08), in: Circle())
            }
            Button { } label: {
                Image(systemName: "lightbulb")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 36, height: 36)
                    .background(.white.opacity(0.08), in: Circle())
            }

            TextField("Ask anything", text: $inputText)
                .font(.system(size: 16))
                .foregroundStyle(.white)
                .tint(selectedProvider.color)
                .focused($inputFocused)
                .submitLabel(.send)
                .onSubmit { if !inputText.isEmpty { navigateToChat = true } }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.white.opacity(0.07), in: Capsule())

            Button {
                if !inputText.isEmpty { navigateToChat = true }
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(inputText.isEmpty ? .white.opacity(0.3) : .black)
                    .frame(width: 36, height: 36)
                    .background(inputText.isEmpty ? AnyShapeStyle(.white.opacity(0.08)) : AnyShapeStyle(Color.white), in: Circle())
            }
            .disabled(inputText.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
