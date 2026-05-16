import Foundation

enum BudgetRule: String, CaseIterable {
    case fiftyThirtyTwenty = "50/30/20"
    case seventyTwentyTen = "70/20/10"
    case custom = "Custom"

    var description: String {
        switch self {
        case .fiftyThirtyTwenty: return "Needs / Wants / Savings"
        case .seventyTwentyTen: return "Spending / Savings / Giving"
        case .custom: return "Set your own splits"
        }
    }

    var splits: (needs: Double, wants: Double, savings: Double) {
        switch self {
        case .fiftyThirtyTwenty: return (0.50, 0.30, 0.20)
        case .seventyTwentyTen: return (0.70, 0.20, 0.10)
        case .custom: return (0.50, 0.30, 0.20)
        }
    }
}

struct BudgetCategory: Identifiable {
    let id: UUID
    var name: String
    var percentage: Double
    var amount: Double
    var spent: Double
    var icon: String
    var colorHex: String

    var remaining: Double { max(amount - spent, 0) }
    var isOverBudget: Bool { spent > amount }
    var spentPercentage: Double { amount > 0 ? min(spent / amount, 1.0) : 0 }
}

struct PaycheckBudget: Codable {
    var paycheckAmount: Double
    var frequency: PayFrequency
    var rule: String
    var needsPercentage: Double
    var wantsPercentage: Double
    var savingsPercentage: Double
    var notificationsEnabled: Bool

    var monthlyIncome: Double {
        switch frequency {
        case .weekly: return paycheckAmount * 52 / 12
        case .biweekly: return paycheckAmount * 26 / 12
        case .semimonthly: return paycheckAmount * 2
        case .monthly: return paycheckAmount
        }
    }

    static let `default` = PaycheckBudget(
        paycheckAmount: 3200,
        frequency: .biweekly,
        rule: BudgetRule.fiftyThirtyTwenty.rawValue,
        needsPercentage: 0.50,
        wantsPercentage: 0.30,
        savingsPercentage: 0.20,
        notificationsEnabled: false
    )
}

enum PayFrequency: String, CaseIterable, Codable {
    case weekly = "Weekly"
    case biweekly = "Bi-weekly"
    case semimonthly = "Semi-monthly"
    case monthly = "Monthly"
}
