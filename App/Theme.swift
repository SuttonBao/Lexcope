import SwiftUI

// Native Apple type, semantic colors, SF Symbols, and Dynamic Type.
enum Theme {
    static let accent = Color(red: 0.19, green: 0.39, blue: 0.32)
    static let fuzzy = Color(red: 0.68, green: 0.43, blue: 0.15)
    static var canvas: Color {
        #if os(iOS)
        Color(uiColor: .systemGroupedBackground)
        #else
        Color(nsColor: .windowBackgroundColor)
        #endif
    }
    static var paper: Color {
        #if os(iOS)
        Color(uiColor: .secondarySystemGroupedBackground)
        #else
        Color(nsColor: .controlBackgroundColor)
        #endif
    }
}

extension View {
    @ViewBuilder func inlineTitle() -> some View {
        #if os(iOS)
        navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }
    func panel() -> some View {
        padding(24).background(Theme.paper, in: RoundedRectangle(cornerRadius: 24))
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline).frame(maxWidth: .infinity).padding(.vertical, 16)
            .foregroundStyle(.white).background(Theme.accent, in: RoundedRectangle(cornerRadius: 16))
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}
