import SwiftUI

struct TransactionRowView: View {
    let transaction: Transaction
    var showNotificationBadge: Bool = true

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(hex: transaction.category.color).opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: transaction.category.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(hex: transaction.category.color))

                if transaction.fromNotification && showNotificationBadge {
                    Circle()
                        .fill(Color.brandOrange)
                        .frame(width: 10, height: 10)
                        .offset(x: 16, y: -16)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(transaction.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.textPrimary)
                Text(transaction.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 12))
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            Text(transaction.formattedAmount)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(transaction.isIncome ? .successGreen : .textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
