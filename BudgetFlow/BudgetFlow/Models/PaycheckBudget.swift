import Foundation

// MARK: - Fixed recurring costs

enum FixedCostCategory: String, CaseIterable, Codable {
    case housing      = "Housing"
    case utilities    = "Utilities"
    case insurance    = "Insurance"
    case phone        = "Phone"
    case subscriptions = "Subscriptions"
    case transport    = "Transport"
    case other        = "Other"

    var icon: String {
        switch self {
        case .housing:       return "house.fill"
        case .utilities:     return "bolt.fill"
        case .insurance:     return "shield.fill"
        case .phone:         return "iphone"
        case .subscriptions: return "repeat.circle.fill"
        case .transport:     return "car.fill"
        case .other:         return "ellipsis.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .housing:       return "4A90E2"
        case .utilities:     return "F39C12"
        case .insurance:     return "27AE60"
        case .phone:         return "9B59B6"
        case .subscriptions: return "E74C3C"
        case .transport:     return "3498DB"
        case .other:         return "95A5A6"
        }
    }

    var defaultEmoji: String {
        switch self {
        case .housing:       return "🏠"
        case .utilities:     return "⚡"
        case .insurance:     return "🛡️"
        case .phone:         return "📱"
        case .subscriptions: return "📺"
        case .transport:     return "🚗"
        case .other:         return "📌"
        }
    }
}

struct FixedCost: Identifiable, Codable {
    let id: UUID
    var name: String
    var amount: Double
    var category: FixedCostCategory
    var emoji: String

    static let sampleData: [FixedCost] = [
        FixedCost(id: UUID(), name: "Rent",          amount: 1200.00, category: .housing,       emoji: "🏠"),
        FixedCost(id: UUID(), name: "Electric",      amount: 92.40,   category: .utilities,     emoji: "⚡"),
        FixedCost(id: UUID(), name: "Car Insurance", amount: 120.00,  category: .insurance,     emoji: "🛡️"),
        FixedCost(id: UUID(), name: "Phone Plan",    amount: 45.00,   category: .phone,         emoji: "📱"),
        FixedCost(id: UUID(), name: "Netflix",       amount: 15.99,   category: .subscriptions, emoji: "📺"),
    ]
}

// MARK: - Budget rule

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
    var fixedCosts: [FixedCost]

    var monthlyIncome: Double {
        switch frequency {
        case .weekly: return paycheckAmount * 52 / 12
        case .biweekly: return paycheckAmount * 26 / 12
        case .semimonthly: return paycheckAmount * 2
        case .monthly: return paycheckAmount
        }
    }

    var totalFixedCosts: Double { fixedCosts.reduce(0) { $0 + $1.amount } }

    /// Income available for needs/wants/savings splits after fixed costs
    var discretionaryIncome: Double { max(monthlyIncome - totalFixedCosts, 0) }

    /// What fraction of monthly income is already committed to fixed costs
    var fixedCostsFraction: Double { monthlyIncome > 0 ? min(totalFixedCosts / monthlyIncome, 1.0) : 0 }

    static let `default` = PaycheckBudget(
        paycheckAmount: 3200,
        frequency: .biweekly,
        rule: BudgetRule.fiftyThirtyTwenty.rawValue,
        needsPercentage: 0.50,
        wantsPercentage: 0.30,
        savingsPercentage: 0.20,
        notificationsEnabled: false,
        fixedCosts: FixedCost.sampleData
    )
}

enum PayFrequency: String, CaseIterable, Codable {
    case weekly = "Weekly"
    case biweekly = "Bi-weekly"
    case semimonthly = "Semi-monthly"
    case monthly = "Monthly"
}
