import SwiftUI

extension Color {
    static let brandOrange = Color(red: 1.0, green: 0.42, blue: 0.21)
    static let brandRed = Color(red: 1.0, green: 0.28, blue: 0.34)
    static let brandAmber = Color(red: 1.0, green: 0.55, blue: 0.0)
    static let appSurface = Color(red: 0.97, green: 0.97, blue: 0.97)
    static let appCard = Color.white
    static let textPrimary = Color(red: 0.10, green: 0.10, blue: 0.10)
    static let textSecondary = Color(red: 0.42, green: 0.44, blue: 0.50)
    static let successGreen = Color(red: 0.20, green: 0.78, blue: 0.35)
    static let warningYellow = Color(red: 1.0, green: 0.80, blue: 0.0)
}

extension LinearGradient {
    static let brand = LinearGradient(
        colors: [.brandOrange, .brandRed],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let brandSubtle = LinearGradient(
        colors: [Color.brandOrange.opacity(0.15), Color.brandRed.opacity(0.08)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let cardDark = LinearGradient(
        colors: [Color(red: 0.12, green: 0.12, blue: 0.12), Color(red: 0.20, green: 0.10, blue: 0.08)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
