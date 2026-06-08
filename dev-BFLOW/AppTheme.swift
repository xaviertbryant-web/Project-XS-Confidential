import SwiftUI

struct AppTheme {
    static let cornerRadius: CGFloat = 20
    static let cardCornerRadius: CGFloat = 24
    static let buttonHeight: CGFloat = 56
    static let horizontalPadding: CGFloat = 20
    static let cardShadowRadius: CGFloat = 12
    static let cardShadowY: CGFloat = 4
    static let cardShadowColor = Color.black.opacity(0.06)

    static func cardShadow() -> some View {
        EmptyView()
    }
}

struct CardModifier: ViewModifier {
    var backgroundColor: Color = .appCard
    func body(content: Content) -> some View {
        content
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
            .shadow(color: AppTheme.cardShadowColor, radius: AppTheme.cardShadowRadius, x: 0, y: AppTheme.cardShadowY)
    }
}

extension View {
    func cardStyle(backgroundColor: Color = .appCard) -> some View {
        modifier(CardModifier(backgroundColor: backgroundColor))
    }
}
