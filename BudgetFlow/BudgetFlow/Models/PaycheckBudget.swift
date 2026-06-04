import Foundation

// MARK: - Billing cycle

enum BillingCycle: String, CaseIterable, Codable {
    case monthly = "Monthly"
    case annual  = "Annual"
    case weekly  = "Weekly"

    var shortLabel: String {
        switch self { case .monthly: return "/mo"; case .annual: return "/yr"; case .weekly: return "/wk" }
    }

    var perMonthMultiplier: Double {
        switch self {
        case .monthly: return 1.0
        case .annual:  return 1.0 / 12.0
        case .weekly:  return 52.0 / 12.0
        }
    }
}

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
    var amount: Double          // as-billed (monthly, annual, or weekly depending on billingCycle)
    var category: FixedCostCategory
    var emoji: String
    var billingCycle: BillingCycle

    /// Always-monthly cost used in budget calculations
    var monthlyEquivalent: Double { amount * billingCycle.perMonthMultiplier }
    var annualCost: Double        { monthlyEquivalent * 12 }

    static let sampleData: [FixedCost] = [
        FixedCost(id: UUID(), name: "Rent",          amount: 1200.00, category: .housing,       emoji: "🏠", billingCycle: .monthly),
        FixedCost(id: UUID(), name: "Electric",      amount: 92.40,   category: .utilities,     emoji: "⚡", billingCycle: .monthly),
        FixedCost(id: UUID(), name: "Car Insurance", amount: 120.00,  category: .insurance,     emoji: "🛡️", billingCycle: .monthly),
        FixedCost(id: UUID(), name: "Phone Plan",    amount: 45.00,   category: .phone,         emoji: "📱", billingCycle: .monthly),
        FixedCost(id: UUID(), name: "Netflix",       amount: 15.99,   category: .subscriptions, emoji: "📺", billingCycle: .monthly),
        FixedCost(id: UUID(), name: "Spotify",       amount: 10.99,   category: .subscriptions, emoji: "🎵", billingCycle: .monthly),
        FixedCost(id: UUID(), name: "iCloud+ 50GB",  amount: 0.99,    category: .subscriptions, emoji: "☁️", billingCycle: .monthly),
    ]
}

// MARK: - Budget bucket & sub-categories

enum BudgetBucket: String, CaseIterable, Codable, Identifiable {
    case needs   = "Needs"
    case wants   = "Wants"
    case savings = "Savings"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .needs:   return "🏠"
        case .wants:   return "🎉"
        case .savings: return "💰"
        }
    }

    var sfIcon: String {
        switch self {
        case .needs:   return "house.fill"
        case .wants:   return "sparkles"
        case .savings: return "chart.line.uptrend.xyaxis"
        }
    }

    var colorHex: String {
        switch self {
        case .needs:   return "FF6B35"
        case .wants:   return "FF4757"
        case .savings: return "33C759"
        }
    }

    var tagline: String {
        switch self {
        case .needs:   return "Essentials & commitments"
        case .wants:   return "Lifestyle & enjoyment"
        case .savings: return "Future you will thank you"
        }
    }

    var suggestions: [(name: String, emoji: String, amount: Double)] {
        switch self {
        case .needs: return [
            ("Groceries",  "🛒", 300), ("Transport",  "🚗", 150), ("Utilities",  "⚡", 90),
            ("Internet",   "📡",  60), ("Phone",      "📱",  45), ("Health Ins.","🏥",180),
            ("Medications","💊",  50), ("Childcare",  "👶", 400), ("Pet Food",   "🐾",  60),
            ("Clothing",   "👕",  80),
        ]
        case .wants: return [
            ("Dining Out",    "🍽️", 200), ("Entertainment","🎬",  80), ("Shopping",    "🛍️", 120),
            ("Gym",           "💪",  40), ("Streaming",    "📺",  50), ("Personal Care","💅",  60),
            ("Hobbies",       "🎨",  80), ("Travel Fund",  "✈️", 150), ("Gaming",       "🎮",  30),
            ("Coffee",        "☕",  50),
        ]
        case .savings: return [
            ("Emergency",  "🛡️", 300), ("Investments", "📈", 200), ("Retirement", "🏦", 150),
            ("Vacation",   "🌴", 100), ("Home Fund",   "🏡", 200), ("Education",  "🎓", 100),
            ("Car Fund",   "🚗", 150), ("Side Hustle", "💼", 100),
        ]
        }
    }
}

struct BudgetSubCategory: Identifiable, Codable {
    let id: UUID
    var name: String
    var emoji: String
    var monthlyAmount: Double
    var bucket: BudgetBucket

    static let defaults: [BudgetSubCategory] = [
        BudgetSubCategory(id: UUID(), name: "Groceries",     emoji: "🛒", monthlyAmount: 300,  bucket: .needs),
        BudgetSubCategory(id: UUID(), name: "Transport",     emoji: "🚗", monthlyAmount: 150,  bucket: .needs),
        BudgetSubCategory(id: UUID(), name: "Utilities",     emoji: "⚡", monthlyAmount: 90,   bucket: .needs),
        BudgetSubCategory(id: UUID(), name: "Dining Out",    emoji: "🍽️", monthlyAmount: 200,  bucket: .wants),
        BudgetSubCategory(id: UUID(), name: "Entertainment", emoji: "🎬", monthlyAmount: 80,   bucket: .wants),
        BudgetSubCategory(id: UUID(), name: "Shopping",      emoji: "🛍️", monthlyAmount: 120,  bucket: .wants),
        BudgetSubCategory(id: UUID(), name: "Emergency",     emoji: "🛡️", monthlyAmount: 300,  bucket: .savings),
        BudgetSubCategory(id: UUID(), name: "Investments",   emoji: "📈", monthlyAmount: 200,  bucket: .savings),
        BudgetSubCategory(id: UUID(), name: "Goals",         emoji: "🎯", monthlyAmount: 100,  bucket: .savings),
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
    var subCategories: [BudgetSubCategory]

    var monthlyIncome: Double {
        switch frequency {
        case .weekly:      return paycheckAmount * 52 / 12
        case .biweekly:    return paycheckAmount * 26 / 12
        case .semimonthly: return paycheckAmount * 2
        case .monthly:     return paycheckAmount
        }
    }

    var totalFixedCosts: Double { fixedCosts.reduce(0) { $0 + $1.monthlyEquivalent } }
    var totalSubscriptions: Double { fixedCosts.filter { $0.category == .subscriptions }.reduce(0) { $0 + $1.monthlyEquivalent } }
    var discretionaryIncome: Double { max(monthlyIncome - totalFixedCosts, 0) }
    var fixedCostsFraction: Double { monthlyIncome > 0 ? min(totalFixedCosts / monthlyIncome, 1.0) : 0 }

    func subCategoryTotal(for bucket: BudgetBucket) -> Double {
        subCategories.filter { $0.bucket == bucket }.reduce(0) { $0 + $1.monthlyAmount }
    }

    var totalSubCategoryAllocation: Double {
        BudgetBucket.allCases.reduce(0) { $0 + subCategoryTotal(for: $1) }
    }

    var unallocated: Double {
        max(monthlyIncome - totalFixedCosts - totalSubCategoryAllocation, 0)
    }

    var isOverAllocated: Bool {
        totalFixedCosts + totalSubCategoryAllocation > monthlyIncome
    }

    static let `default` = PaycheckBudget(
        paycheckAmount: 3200,
        frequency: .biweekly,
        rule: BudgetRule.fiftyThirtyTwenty.rawValue,
        needsPercentage: 0.50,
        wantsPercentage: 0.30,
        savingsPercentage: 0.20,
        notificationsEnabled: false,
        fixedCosts: FixedCost.sampleData,
        subCategories: BudgetSubCategory.defaults
    )
}

enum PayFrequency: String, CaseIterable, Codable {
    case weekly = "Weekly"
    case biweekly = "Bi-weekly"
    case semimonthly = "Semi-monthly"
    case monthly = "Monthly"
}
