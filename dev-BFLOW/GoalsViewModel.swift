import SwiftUI

class GoalsViewModel: ObservableObject {
    @Published var showingAddGoal: Bool = false
    @Published var selectedGoal: Goal?
    @Published var showingGoalDetail: Bool = false
    @Published var newGoalTitle: String = ""
    @Published var newGoalTarget: String = ""
    @Published var newGoalCategory: GoalCategory = .custom
    @Published var newGoalEmoji: String = "⭐"
    @Published var newGoalMonthly: String = ""

    let emojiOptions = ["⭐", "✈️", "🏠", "🚗", "💻", "📱", "🎓", "🛡️", "💰", "🎯", "🌴", "💎"]

    func resetNewGoalForm() {
        newGoalTitle = ""
        newGoalTarget = ""
        newGoalCategory = .custom
        newGoalEmoji = "⭐"
        newGoalMonthly = ""
    }

    func buildGoal() -> Goal? {
        guard !newGoalTitle.isEmpty,
              let target = Double(newGoalTarget), target > 0,
              let monthly = Double(newGoalMonthly), monthly > 0 else { return nil }
        return Goal(
            id: UUID(),
            title: newGoalTitle,
            targetAmount: target,
            currentAmount: 0,
            category: newGoalCategory,
            targetDate: Date().addingTimeInterval(86400 * 365),
            emoji: newGoalEmoji,
            isCompleted: false,
            completedDate: nil,
            monthlyContribution: monthly
        )
    }
}
