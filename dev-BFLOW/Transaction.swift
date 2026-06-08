import Foundation

enum TransactionCategory: String, CaseIterable, Codable {
    case food = "Food & Dining"
    case transport = "Transport"
    case shopping = "Shopping"
    case entertainment = "Entertainment"
    case bills = "Bills & Utilities"
    case health = "Health"
    case income = "Income"
    case transfer = "Transfer"
    case other = "Other"

    var icon: String {
        switch self {
        case .food: return "fork.knife"
        case .transport: return "car.fill"
        case .shopping: return "bag.fill"
        case .entertainment: return "tv.fill"
        case .bills: return "bolt.fill"
        case .health: return "heart.fill"
        case .income: return "arrow.down.circle.fill"
        case .transfer: return "arrow.left.arrow.right"
        case .other: return "ellipsis.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .food: return "FF6B35"
        case .transport: return "4A90E2"
        case .shopping: return "9B59B6"
        case .entertainment: return "E74C3C"
        case .bills: return "F39C12"
        case .health: return "2ECC71"
        case .income: return "27AE60"
        case .transfer: return "3498DB"
        case .other: return "95A5A6"
        }
    }
}

struct Transaction: Identifiable, Codable {
    let id: UUID
    var title: String
    var amount: Double
    var category: TransactionCategory
    var date: Date
    var isIncome: Bool
    var merchant: String
    var fromNotification: Bool

    var formattedAmount: String {
        let prefix = isIncome ? "+" : "-"
        return "\(prefix)$\(String(format: "%.2f", abs(amount)))"
    }

    static let sampleData: [Transaction] = [
        Transaction(id: UUID(), title: "Salary Deposit", amount: 3200, category: .income, date: Date().addingTimeInterval(-86400 * 2), isIncome: true, merchant: "Employer Inc", fromNotification: false),
        Transaction(id: UUID(), title: "Whole Foods Market", amount: 84.32, category: .food, date: Date().addingTimeInterval(-3600 * 5), isIncome: false, merchant: "Whole Foods", fromNotification: true),
        Transaction(id: UUID(), title: "Uber", amount: 12.50, category: .transport, date: Date().addingTimeInterval(-3600 * 8), isIncome: false, merchant: "Uber", fromNotification: true),
        Transaction(id: UUID(), title: "Netflix", amount: 15.99, category: .entertainment, date: Date().addingTimeInterval(-86400), isIncome: false, merchant: "Netflix", fromNotification: false),
        Transaction(id: UUID(), title: "Zara", amount: 67.00, category: .shopping, date: Date().addingTimeInterval(-86400 * 3), isIncome: false, merchant: "Zara", fromNotification: false),
        Transaction(id: UUID(), title: "Electric Bill", amount: 92.40, category: .bills, date: Date().addingTimeInterval(-86400 * 4), isIncome: false, merchant: "City Power", fromNotification: false),
        Transaction(id: UUID(), title: "Starbucks", amount: 6.50, category: .food, date: Date().addingTimeInterval(-3600 * 2), isIncome: false, merchant: "Starbucks", fromNotification: true),
    ]
}
