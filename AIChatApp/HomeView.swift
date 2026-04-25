import SwiftUI

// MARK: - HomeView
struct HomeView: View {
    @State private var selectedProvider = ALL_PROVIDERS[0]
    @State private var selectedModel: AIModel = ALL_PROVIDERS[0].models[0]
    @State private var inputText = ""
    @State private var navigateToChat = false
    @State private var showSettings = false
    @State private var isLoadingModel = true
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
                // Black base
                Color.black.ignoresSafeArea()
                
                // Radial gradient glow (Deep Navy/Blue)
                RadialGradient(
                    colors: [
                        selectedProvider.color.opacity(0.35),
                        selectedProvider.color.opacity(0.18),
                        .clear
                    ],
                    center: .init(x: 0.5, y: 0.2),
                    startRadius: 0,
                    endRadius: 420
                )
                .blur(radius: 90)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.8), value: selectedProvider.id)

                VStack(spacing: 0) {
                    topBar
                    Spacer()
                    
                    if isLoadingModel {
                        loadingView
                    } else {
                        centerTitle
                    }
                    
                    Spacer()
                    suggestionChips
                    inputBar
                }
            }
            .navigationDestination(isPresented: $navigateToChat) {
                ChatView(provider: selectedProvider, model: selectedModel, initialMessage: inputText)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(selectedProvider: $selectedProvider, selectedModel: $selectedModel)
            }
        }
        .preferredColorScheme(.dark)
        .task {
            // Simulate model loading
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            withAnimation(.easeInOut(duration: 0.6)) { isLoadingModel = false }
        }
    }

    // MARK: Top Bar (Header) с настоящим liquid glass
    var topBar: some View {
        HStack(spacing: 12) {
            // Settings + History combined button
            Menu {
                Button {
                    showSettings = true
                } label: {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                Button { } label: {
                    Label("History", systemImage: "bubble.left.fill")
                }
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.title3.bold())
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .controlSize(.regular)

            Spacer()

            // Current model pill
            Button { showSettings = true } label: {
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
                            .padding(.vertical, 3)
                            .background(selectedProvider.color.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.capsule)
            .controlSize(.regular)
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: selectedModel.id)

            Spacer()

            // New chat button
            Button { inputText = ""; navigateToChat = true } label: {
                Image(systemName: "square.and.pencil")
                    .font(.title3.bold())
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .controlSize(.regular)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: Loading View
    var loadingView: some View {
        VStack(spacing: 20) {
            Text("Meet \(selectedProvider.name)")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text("Run \(selectedProvider.name)'s ultra-efficient model locally — built for fast on-device performance.")
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 40)
            
            // Loading indicator с настоящим liquid glass
            Button { } label: {
                HStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white.opacity(0.6)))
                        .scaleEffect(0.8)
                    Text("Loading model...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .buttonStyle(.glass)
            .disabled(true)
            .padding(.top, 20)
        }
        .padding(.horizontal, 32)
    }

    // MARK: Center Title (Main Hero Section)
    var centerTitle: some View {
        VStack(spacing: 16) {
            Text("Meet \(selectedProvider.name)")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text("Free AI at your fingertips.\nNo account required.")
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(.horizontal, 32)
    }

    // MARK: Suggestion Chips (Action Cards) - квадратные без liquid glass
    var suggestionChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(suggestions.enumerated()), id: \.offset) { _, s in
                    Button {
                        inputText = "\(s.0) \(s.1)"
                        navigateToChat = true
                    } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(s.0)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                            Text(s.1)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        .frame(width: 150, alignment: .leading)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 16)
    }

    // MARK: Input Bar (Sticky Bottom)
    var inputBar: some View {
        HStack(spacing: 10) {
            // Plus button
            Button { } label: {
                Image(systemName: "plus")
                    .font(.title3.bold())
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .controlSize(.regular)
            
            // Lightbulb button
            Button { } label: {
                Image(systemName: "lightbulb.fill")
                    .font(.title3.bold())
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .controlSize(.regular)

            // Text input
            ZStack {
                Capsule()
                    .fill(.ultraThinMaterial)
                
                TextField("Ask anything", text: $inputText)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.white)
                    .tint(selectedProvider.color)
                    .focused($inputFocused)
                    .submitLabel(.send)
                    .onSubmit { if !inputText.isEmpty { navigateToChat = true } }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 13)
            }
            .frame(height: 44)

            // Send button - полностью белая
            if inputText.isEmpty {
                Button { } label: {
                    Image(systemName: "arrow.up")
                        .font(.title3.bold())
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .controlSize(.regular)
                .disabled(true)
            } else {
                Button {
                    navigateToChat = true
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(.white))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .padding(.bottom, 8)
    }
}
