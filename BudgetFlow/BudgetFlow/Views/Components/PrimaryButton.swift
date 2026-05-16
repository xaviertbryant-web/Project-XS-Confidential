import SwiftUI

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isLoading: Bool = false
    var style: ButtonStyle = .filled

    enum ButtonStyle { case filled, outlined, ghost }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: AppTheme.buttonHeight)
            .background(backgroundView)
            .foregroundColor(foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(LinearGradient.brand, lineWidth: style == .outlined ? 2 : 0)
            )
        }
        .disabled(isLoading)
    }

    @ViewBuilder
    var backgroundView: some View {
        switch style {
        case .filled: LinearGradient.brand
        case .outlined: Color.clear
        case .ghost: Color.brandOrange.opacity(0.1)
        }
    }

    var foregroundColor: Color {
        switch style {
        case .filled: .white
        case .outlined: .brandOrange
        case .ghost: .brandOrange
        }
    }
}

struct IconButton: View {
    let icon: String
    let action: () -> Void
    var size: CGFloat = 44
    var tint: Color = .brandOrange

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(tint)
                .frame(width: size, height: size)
                .background(tint.opacity(0.1))
                .clipShape(Circle())
        }
    }
}
