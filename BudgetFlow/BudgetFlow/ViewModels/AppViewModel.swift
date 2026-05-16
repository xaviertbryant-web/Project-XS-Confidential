import SwiftUI
import Combine

@MainActor
class AppViewModel: ObservableObject {
    @Published var profile: UserProfile = .default
    @Published var transactions: [Transaction] = Transaction.sampleData
    @Published var goals: [Goal] = Goal.sampleData
    @Published var paycheckBudget: PaycheckBudget = .default
    @Published var insights: [Insight] = Insight.sampleData
    @Published var selectedTab: Int = 0
    @Published var showingGoalCompletion: Bool = false
    @Published var completedGoal: Goal?
    @Published var applePayLocked: Bool = false
    @Published var showApplePayLock: Bool = false

    var totalSpentThisMonth: Double {
        transactions.filter { !$0.isIncome && Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
    }

    var totalIncomeThisMonth: Double {
        transactions.filter { $0.isIncome && Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
    }

    var savedThisMonth: Double {
        max(totalIncomeThisMonth - totalSpentThisMonth, 0)
    }

    var spendingByCategory: [(category: TransactionCategory, amount: Double)] {
        let expenses = transactions.filter { !$0.isIncome }
        let grouped = Dictionary(grouping: expenses, by: { $0.category })
        return grouped.map { (category: $0.key, amount: $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.amount > $1.amount }
    }

    func addTransaction(_ transaction: Transaction) {
        transactions.insert(transaction, at: 0)
    }

    func updateGoalAmount(_ goal: Goal, newAmount: Double) {
        guard let index = goals.firstIndex(where: { $0.id == goal.id }) else { return }
        goals[index].currentAmount = newAmount
        if goals[index].currentAmount >= goals[index].targetAmount && !goals[index].isCompleted {
            goals[index].isCompleted = true
            goals[index].completedDate = Date()
            completedGoal = goals[index]
            showingGoalCompletion = true
        }
    }

    func addGoal(_ goal: Goal) {
        goals.append(goal)
    }

    func monthlyProjections() -> [SpendingProjection] {
        let calendar = Calendar.current
        let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        let currentMonth = calendar.component(.month, from: Date()) - 1

        return (0..<6).map { offset in
            let monthIndex = (currentMonth + offset) % 12
            let projected = paycheckBudget.monthlyIncome * paycheckBudget.savingsPercentage * (1.0 + Double(offset) * 0.02)
            return SpendingProjection(
                month: months[monthIndex],
                projected: projected,
                actual: offset == 0 ? savedThisMonth : nil
            )
        }
    }
}
