import SwiftUI

struct CategoryBadge: View {
    let category: TransactionCategory
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: category.icon)
                .font(.system(size: compact ? 10 : 12, weight: .semibold))
            if !compact {
                Text(category.rawValue)
                    .font(.system(size: 11, weight: .semibold))
            }
        }
        .foregroundColor(Color(hex: category.color))
        .padding(.horizontal, compact ? 6 : 10)
        .padding(.vertical, compact ? 4 : 6)
        .background(Color(hex: category.color).opacity(0.12))
        .clipShape(Capsule())
    }
}

struct SpendingBarView: View {
    let label: String
    let spent: Double
    let budget: Double
    let color: Color

    var progress: Double { budget > 0 ? min(spent / budget, 1.0) : 0 }
    var isOver: Bool { spent > budget }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.textPrimary)
                Spacer()
                Text("$\(String(format: "%.0f", spent)) / $\(String(format: "%.0f", budget))")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isOver ? .brandRed : .textSecondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(color.opacity(0.15))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isOver ? LinearGradient(colors: [.brandOrange, .brandRed], startPoint: .leading, endPoint: .trailing) : LinearGradient(colors: [color], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * progress, height: 8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
                }
            }
            .frame(height: 8)
        }
    }
}
