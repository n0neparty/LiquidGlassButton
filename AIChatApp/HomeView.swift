import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    @Published var models: [String: [AIModel]] = [:]
    @Published var selectedProvider: Provider = PROVIDERS[0]
    @Published var selectedModel: AIModel? = nil
    @Published var isLoading = false

    func loadModels() async {
        isLoading = true
        await withTaskGroup(of: (String, [AIModel]).self) { group in
            for provider in PROVIDERS {
                group.addTask {
                    let models = (try? await APIService.shared.fetchModels(provider: provider.id)) ?? []
                    return (provider.id, models)
                }
            }
            for await (id, models) in group {
                self.models[id] = models
            }
        }
        // Выбираем первую модель
        if let first = models[selectedProvider.id]?.first {
            selectedModel = first
        }
        isLoading = false
    }

    func selectProvider(_ provider: Provider) {
        selectedProvider = provider
        selectedModel = models[provider.id]?.first
    }
}

struct HomeView: View {
    @StateObject private var vm = HomeViewModel()
    @State private var navigateToChat = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color(hex: "#0a0a0f"), Color(hex: "#0f0a1a"), Color(hex: "#0a0f0a")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Ambient blobs
                GeometryReader { geo in
                    Circle()
                        .fill(Color(hex: "#6366f1").opacity(0.15))
                        .frame(width: 300, height: 300)
                        .blur(radius: 80)
                        .offset(x: -50, y: -100)
                    Circle()
                        .fill(Color(hex: "#ec4899").opacity(0.1))
                        .frame(width: 250, height: 250)
                        .blur(radius: 80)
                        .offset(x: geo.size.width - 150, y: geo.size.height - 300)
                }
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("AI Chat")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Выбери провайдера и модель")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 20)

                    // Providers scroll
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(PROVIDERS) { provider in
                                Button {
                                    withAnimation(.spring(response: 0.3)) {
                                        vm.selectProvider(provider)
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(Color(hex: provider.color))
                                            .frame(width: 8, height: 8)
                                        Text(provider.name)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundStyle(.white)
                                    }
                                }
                                .buttonStyle(GlassButtonStyle(
                                    color: Color(hex: provider.color),
                                    isSelected: vm.selectedProvider.id == provider.id
                                ))
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 16)

                    // Models list
                    if vm.isLoading {
                        Spacer()
                        ProgressView()
                            .tint(.white)
                        Spacer()
                    } else {
                        let providerModels = vm.models[vm.selectedProvider.id] ?? []

                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(providerModels) { model in
                                    Button {
                                        withAnimation(.spring(response: 0.25)) {
                                            vm.selectedModel = model
                                        }
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(model.displayName)
                                                    .font(.system(size: 16, weight: .medium))
                                                    .foregroundStyle(.white)
                                                if let cost = model.cost {
                                                    Text(cost == 0 ? "Бесплатно" : "\(cost)/день")
                                                        .font(.caption)
                                                        .foregroundStyle(.white.opacity(0.45))
                                                }
                                            }
                                            Spacer()
                                            if vm.selectedModel?.id == model.id {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundStyle(Color(hex: vm.selectedProvider.color))
                                                    .font(.title3)
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 14)
                                    }
                                    .buttonStyle(GlassButtonStyle(
                                        color: Color(hex: vm.selectedProvider.color),
                                        isSelected: vm.selectedModel?.id == model.id
                                    ))
                                    .padding(.horizontal, 20)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }

                    // Start button
                    NavigationLink(
                        destination: ChatView(
                            provider: vm.selectedProvider,
                            model: vm.selectedModel ?? AIModel(id: "", name: nil, cost: nil)
                        )
                    ) {
                        HStack {
                            Text("Начать чат")
                                .font(.system(size: 17, weight: .semibold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: vm.selectedProvider.color),
                                            Color(hex: vm.selectedProvider.color).opacity(0.7)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [.white.opacity(0.2), .clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(.white.opacity(0.25), lineWidth: 0.8)
                        }
                    }
                    .disabled(vm.selectedModel == nil)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                    .padding(.top, 12)
                }
            }
            .navigationBarHidden(true)
        }
        .task { await vm.loadModels() }
    }
}
