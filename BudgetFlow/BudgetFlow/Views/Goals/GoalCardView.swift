import SwiftUI

struct GoalCardView: View {
    let goal: Goal
    var onTap: (() -> Void)? = nil
    @State private var appeared = false

    var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(goal.emoji)
                        .font(.system(size: 28))
                    Spacer()
                    if goal.isCompleted {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(LinearGradient.brand)
                    } else {
                        CircularProgressView(progress: goal.progress, size: 50, lineWidth: 5, showPercentage: true)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)

                    Text(goal.isCompleted ? "Completed! 🎉" : "$\(String(format: "%.0f", goal.remaining)) to go")
                        .font(.system(size: 12))
                        .foregroundColor(goal.isCompleted ? .successGreen : .textSecondary)
                }

                if !goal.isCompleted {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.brandOrange.opacity(0.12))
                                .frame(height: 5)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(LinearGradient.brand)
                                .frame(width: appeared ? geo.size.width * goal.progress : 0, height: 5)
                                .animation(.spring(response: 1.0, dampingFraction: 0.8).delay(0.2), value: appeared)
                        }
                    }
                    .frame(height: 5)

                    Text("$\(String(format: "%.0f", goal.monthlyContribution))/mo contribution")
                        .font(.system(size: 11))
                        .foregroundColor(.textSecondary)
                }
            }
            .padding(16)
            .cardStyle()
        }
        .buttonStyle(.plain)
        .onAppear { appeared = true }
    }
}
