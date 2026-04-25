import SwiftUI

// MARK: - Debug Settings для настройки размеров кнопок
class DebugSettings: ObservableObject {
    @Published var buttonSize: CGFloat = 38
    
    static let shared = DebugSettings()
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
                    Section("Button Size") {
                        HStack {
                            Text("Size: \(Int(settings.buttonSize))")
                                .foregroundStyle(.white)
                            Spacer()
                            Stepper("", value: $settings.buttonSize, in: 30...50, step: 1)
                        }
                        
                        Slider(value: $settings.buttonSize, in: 30...50, step: 1)
                        
                        Text("Current: \(Int(settings.buttonSize))x\(Int(settings.buttonSize))")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                    
                    Section {
                        Button("Reset to Default (38)") {
                            settings.buttonSize = 38
                        }
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
