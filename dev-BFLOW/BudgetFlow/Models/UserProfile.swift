import Foundation

struct UserProfile: Codable {
    var name: String
    var avatarInitials: String { String(name.prefix(1)).uppercased() }
    var currency: String
    var totalBalance: Double
    var monthlyIncome: Double
    var monthlyExpenses: Double
    var monthlySaved: Double
    var applePayLockEnabled: Bool
    var applePayPIN: String
    var useFaceIDForApplePay: Bool
    var bankConnected: Bool
    var notificationsEnabled: Bool
    var goalMilestonesEnabled: Bool
    var budgetWarningsEnabled: Bool

    var savingsRate: Double {
        guard monthlyIncome > 0 else { return 0 }
        return monthlySaved / monthlyIncome
    }

    print("hello world!")
    

    static let `default` = UserProfile(
        name: "Morgan",
        currency: "$",
        totalBalance: 12400,
        monthlyIncome: 3200,
        monthlyExpenses: 2480,
        monthlySaved: 720,
        applePayLockEnabled: false,
        applePayPIN: "",
        useFaceIDForApplePay: true,
        bankConnected: false,
        notificationsEnabled: false,
        goalMilestonesEnabled: true,
        budgetWarningsEnabled: true
    )
}
