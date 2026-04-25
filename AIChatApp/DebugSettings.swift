import SwiftUI

// MARK: - Debug Settings для настройки всех параметров UI
@MainActor
class DebugSettings: ObservableObject {
    // Button sizes
    @Published var buttonSize: CGFloat = 34
    @Published var modelPillHeight: CGFloat = 32
    
    // Spacing
    @Published var inputBarSpacing: CGFloat = 5
    @Published var topBarSpacing: CGFloat = 12
    @Published var suggestionChipsSpacing: CGFloat = 12
    @Published var messageSpacing: CGFloat = 16
    
    // Padding
    @Published var inputBarHorizontalPadding: CGFloat = 16
    @Published var inputBarVerticalPadding: CGFloat = 12
    @Published var topBarHorizontalPadding: CGFloat = 11
    @Published var topBarTopPadding: CGFloat = 7
    @Published var modelPillHorizontalPadding: CGFloat = 14
    @Published var modelPillVerticalPadding: CGFloat = 8
    @Published var suggestionChipHorizontalPadding: CGFloat = 14
    @Published var suggestionChipVerticalPadding: CGFloat = 12
    @Published var messageBubbleHorizontalPadding: CGFloat = 16
    @Published var messageBubbleVerticalPadding: CGFloat = 12
    
    // Font sizes
    @Published var buttonIconSize: CGFloat = 20
    @Published var modelPillIconSize: CGFloat = 13
    @Published var modelPillTextSize: CGFloat = 15
    @Published var modelPillBadgeSize: CGFloat = 11
    @Published var suggestionTitleSize: CGFloat = 16
    @Published var suggestionSubtitleSize: CGFloat = 14
    @Published var messageTextSize: CGFloat = 15
    
    // Corner radius
    @Published var suggestionChipCornerRadius: CGFloat = 12
    @Published var messageBubbleCornerRadius: CGFloat = 20
    @Published var settingsCardCornerRadius: CGFloat = 16
    
    // Suggestion chips
    @Published var suggestionChipWidth: CGFloat = 150
    @Published var suggestionChipSpacing: CGFloat = 5
    
    static let shared = DebugSettings()
    
    func resetToDefaults() {
        buttonSize = 34
        modelPillHeight = 32
        
        inputBarSpacing = 5
        topBarSpacing = 12
        suggestionChipsSpacing = 12
        messageSpacing = 16
        
        inputBarHorizontalPadding = 16
        inputBarVerticalPadding = 12
        topBarHorizontalPadding = 11
        topBarTopPadding = 7
        modelPillHorizontalPadding = 14
        modelPillVerticalPadding = 8
        suggestionChipHorizontalPadding = 14
        suggestionChipVerticalPadding = 12
        messageBubbleHorizontalPadding = 16
        messageBubbleVerticalPadding = 12
        
        buttonIconSize = 20
        modelPillIconSize = 13
        modelPillTextSize = 15
        modelPillBadgeSize = 11
        suggestionTitleSize = 16
        suggestionSubtitleSize = 14
        messageTextSize = 15
        
        suggestionChipCornerRadius = 12
        messageBubbleCornerRadius = 20
        settingsCardCornerRadius = 16
        
        suggestionChipWidth = 150
        suggestionChipSpacing = 5
    }
}

// MARK: - Debug Settings View
struct DebugSettingsView: View {
    @ObservedObject var settings = DebugSettings.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                Form {
                    // Button Sizes
                    Section("Button Sizes") {
                        SettingSlider(title: "Button Size", value: $settings.buttonSize, range: 28...50)
                        SettingSlider(title: "Model Pill Height", value: $settings.modelPillHeight, range: 24...44)
                    }
                    
                    // Spacing
                    Section("Spacing") {
                        SettingSlider(title: "Input Bar Spacing", value: $settings.inputBarSpacing, range: 4...20)
                        SettingSlider(title: "Top Bar Spacing", value: $settings.topBarSpacing, range: 4...24)
                        SettingSlider(title: "Suggestion Chips Spacing", value: $settings.suggestionChipsSpacing, range: 4...24)
                        SettingSlider(title: "Message Spacing", value: $settings.messageSpacing, range: 8...32)
                        SettingSlider(title: "Suggestion Chip Internal", value: $settings.suggestionChipSpacing, range: 2...12)
                    }
                    
                    // Padding
                    Section("Padding - Input Bar") {
                        SettingSlider(title: "Horizontal", value: $settings.inputBarHorizontalPadding, range: 8...32)
                        SettingSlider(title: "Vertical", value: $settings.inputBarVerticalPadding, range: 4...24)
                    }
                    
                    Section("Padding - Top Bar") {
                        SettingSlider(title: "Horizontal", value: $settings.topBarHorizontalPadding, range: 8...32)
                        SettingSlider(title: "Top", value: $settings.topBarTopPadding, range: 0...24)
                    }
                    
                    Section("Padding - Model Pill") {
                        SettingSlider(title: "Horizontal", value: $settings.modelPillHorizontalPadding, range: 8...24)
                        SettingSlider(title: "Vertical", value: $settings.modelPillVerticalPadding, range: 4...16)
                    }
                    
                    Section("Padding - Suggestion Chips") {
                        SettingSlider(title: "Horizontal", value: $settings.suggestionChipHorizontalPadding, range: 8...24)
                        SettingSlider(title: "Vertical", value: $settings.suggestionChipVerticalPadding, range: 6...20)
                        SettingSlider(title: "Width", value: $settings.suggestionChipWidth, range: 120...200)
                    }
                    
                    Section("Padding - Message Bubbles") {
                        SettingSlider(title: "Horizontal", value: $settings.messageBubbleHorizontalPadding, range: 8...24)
                        SettingSlider(title: "Vertical", value: $settings.messageBubbleVerticalPadding, range: 6...20)
                    }
                    
                    // Font Sizes
                    Section("Font Sizes - Buttons") {
                        SettingSlider(title: "Button Icon", value: $settings.buttonIconSize, range: 14...28)
                    }
                    
                    Section("Font Sizes - Model Pill") {
                        SettingSlider(title: "Icon", value: $settings.modelPillIconSize, range: 10...18)
                        SettingSlider(title: "Text", value: $settings.modelPillTextSize, range: 12...20)
                        SettingSlider(title: "Badge", value: $settings.modelPillBadgeSize, range: 8...14)
                    }
                    
                    Section("Font Sizes - Suggestions") {
                        SettingSlider(title: "Title", value: $settings.suggestionTitleSize, range: 12...22)
                        SettingSlider(title: "Subtitle", value: $settings.suggestionSubtitleSize, range: 10...18)
                    }
                    
                    Section("Font Sizes - Messages") {
                        SettingSlider(title: "Text", value: $settings.messageTextSize, range: 12...20)
                    }
                    
                    // Corner Radius
                    Section("Corner Radius") {
                        SettingSlider(title: "Suggestion Chips", value: $settings.suggestionChipCornerRadius, range: 8...24)
                        SettingSlider(title: "Message Bubbles", value: $settings.messageBubbleCornerRadius, range: 12...32)
                        SettingSlider(title: "Settings Cards", value: $settings.settingsCardCornerRadius, range: 12...24)
                    }
                    
                    // Reset
                    Section {
                        Button("Reset All to Defaults") {
                            settings.resetToDefaults()
                        }
                        .foregroundStyle(.red)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Debug Settings")
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

// MARK: - Setting Slider Component
struct SettingSlider: View {
    let title: String
    @Binding var value: CGFloat
    let range: ClosedRange<CGFloat>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .foregroundStyle(.white)
                Spacer()
                Text("\(Int(value))")
                    .foregroundStyle(.gray)
                    .monospacedDigit()
            }
            
            HStack(spacing: 12) {
                Button {
                    if value > range.lowerBound {
                        value -= 1
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(.white.opacity(0.6))
                }
                
                Slider(value: $value, in: range, step: 1)
                
                Button {
                    if value < range.upperBound {
                        value += 1
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
    }
}
