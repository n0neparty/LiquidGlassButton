import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedProvider: AIProvider
    @Binding var selectedModel: AIModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Black base
                Color.black.ignoresSafeArea()
                
                // Subtle radial gradient
                RadialGradient(
                    colors: [
                        selectedProvider.color.opacity(0.25),
                        selectedProvider.color.opacity(0.12),
                        .clear
                    ],
                    center: .init(x: 0.5, y: 0.2),
                    startRadius: 0,
                    endRadius: 400
                )
                .blur(radius: 90)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.7), value: selectedProvider.id)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Provider Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("AI Provider")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.5))
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 8) {
                                ForEach(ALL_PROVIDERS) { provider in
                                    Button {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                            selectedProvider = provider
                                            selectedModel = provider.models[0]
                                        }
                                    } label: {
                                        HStack(spacing: 12) {
                                            Image(systemName: provider.icon)
                                                .font(.system(size: 18, weight: .semibold))
                                                .foregroundStyle(provider.color)
                                                .frame(width: 36, height: 36)
                                                .background(provider.color.opacity(0.15))
                                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                            
                                            Text(provider.name)
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundStyle(.white)
                                            
                                            Spacer()
                                            
                                            if selectedProvider.id == provider.id {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 20))
                                                    .foregroundStyle(provider.color)
                                                    .transition(.scale.combined(with: .opacity))
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        
                        // Model Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Model")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.5))
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 8) {
                                ForEach(selectedProvider.models) { model in
                                    Button {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                            selectedModel = model
                                        }
                                    } label: {
                                        HStack(spacing: 12) {
                                            VStack(alignment: .leading, spacing: 4) {
                                                HStack(spacing: 6) {
                                                    Text(model.name)
                                                        .font(.system(size: 15, weight: .medium))
                                                        .foregroundStyle(.white)
                                                    
                                                    if let badge = model.badge {
                                                        Text(badge)
                                                            .font(.system(size: 10, weight: .bold))
                                                            .foregroundStyle(selectedProvider.color)
                                                            .padding(.horizontal, 6)
                                                            .padding(.vertical, 3)
                                                            .background(selectedProvider.color.opacity(0.2))
                                                            .clipShape(Capsule())
                                                    }
                                                }
                                                
                                                Text("\(model.apiProvider) • \(model.apiModel)")
                                                    .font(.system(size: 12, weight: .regular))
                                                    .foregroundStyle(.white.opacity(0.4))
                                            }
                                            
                                            Spacer()
                                            
                                            if selectedModel.id == model.id {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 20))
                                                    .foregroundStyle(selectedProvider.color)
                                                    .transition(.scale.combined(with: .opacity))
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
