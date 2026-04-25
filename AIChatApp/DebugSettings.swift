import SwiftUI

// MARK: - Debug Settings для настройки всех параметров UI
class DebugSettings: ObservableObject {
    // Button sizes
    @Published var buttonSize: CGFloat = 34
    @Published var modelPillHeight: CGFloat = 32
    
    // Spacing
    @Published var inputBarSpacing: CGFloat = 20
    @Published var topBarSpacing: CGFloat = 8
    @Published var suggestionChipsSpacing: CGFloat = 12
    @Published var messageSpacing: CGFloat = 16
    
    // Padding
    @Published var inputBarHorizontalPadding: CGFloat = 20
    @Published var inputBarVerticalPadding: CGFloat = 17
    @Published var topBarHorizontalPadding: CGFloat = 16
    @Published var topBarTopPadding: CGFloat = 6
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
}
