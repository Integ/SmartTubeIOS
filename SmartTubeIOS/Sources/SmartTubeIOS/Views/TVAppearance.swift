import SwiftUI

#if os(tvOS)
/// Shared living-room layout and focus styling.
enum TVAppearance {
    static let background = Color(white: 0.055)
    static let surface = Color(white: 0.14)
    static let muted = Color(white: 0.65)
    static let accent = Color(red: 0.95, green: 0.12, blue: 0.16)
    static let sidebarWidth: CGFloat = 210
    static let collapsedSidebarWidth: CGFloat = 96
    static let contentInset: CGFloat = 16
    static let topInset: CGFloat = 16
    static let columnCount = 3
    static let cardSpacing: CGFloat = 28
    static let cornerRadius: CGFloat = 12
    static let focusScale: CGFloat = 1.035
    static let focusDuration: TimeInterval = 0.16
}

struct TVControlStyle: ButtonStyle {
    @Environment(\.isFocused) private var isFocused
    var selected = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 21, weight: .semibold))
            .foregroundStyle(isFocused ? .black : .white)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(isFocused ? Color.white : (selected ? Color(white: 0.28) : TVAppearance.surface))
            .clipShape(RoundedRectangle(cornerRadius: TVAppearance.cornerRadius))
            .scaleEffect(configuration.isPressed ? 0.98 : (isFocused ? TVAppearance.focusScale : 1))
            .animation(.easeOut(duration: TVAppearance.focusDuration), value: isFocused)
    }
}
#endif

enum AccessibilityID {
    static let tvSidebar = "tv.sidebar"
    static let tvRefresh = "tv.refresh"
    static let tvAccount = "tv.account"
    static func tvNavigation(_ section: String) -> String { "tv.navigation.\(section)" }
}
