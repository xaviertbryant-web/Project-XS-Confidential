import Foundation

enum GoalCategory: String, CaseIterable, Codable {
    case emergency = "Emergency Fund"
    case travel = "Travel"
    case gadget = "Tech & Gadgets"
    case home = "Home"
    case car = "Car"
    case education = "Education"
    case investment = "Investment"
    case custom = "Custom"

    var icon: String {
        switch self {
        case .emergency: return "shield.fill"
        case .travel: return "airplane"
        case .gadget: return "iphone"
        case .home: return "house.fill"
        case .car: return "car.fill"
        case .education: return "graduationcap.fill"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .custom: return "star.fill"
        }
    }
}

struct Goal: Identifiable, Codable {
    let id: UUID
    var title: String
    var targetAmount: Double
    var currentAmount: Double
    var category: GoalCategory
    var targetDate: Date
    var emoji: String
    var isCompleted: Bool
    var completedDate: Date?
    var monthlyContribution: Double

    var progress: Double {
        guard targetAmount > 0 else { return 0 }
        return min(currentAmount / targetAmount, 1.0)
    }

    var progressPercentage: Int {
        Int(progress * 100)
    }

    var remaining: Double {
        max(targetAmount - currentAmount, 0)
    }

    var monthsToGoal: Int {
        guard monthlyContribution > 0 && remaining > 0 else { return 0 }
        return Int(ceil(remaining / monthlyContribution))
    }

    var projectedCompletionDate: Date {
        Calendar.current.date(byAdding: .month, value: monthsToGoal, to: Date()) ?? targetDate
    }

    static let sampleData: [Goal] = [
        Goal(id: UUID(), title: "Japan Trip", targetAmount: 3000, currentAmount: 1850, category: .travel, targetDate: Date().addingTimeInterval(86400 * 120), emoji: "✈️", isCompleted: false, completedDate: nil, monthlyContribution: 300),
        Goal(id: UUID(), title: "Emergency Fund", targetAmount: 5000, currentAmount: 3200, category: .emergency, targetDate: Date().addingTimeInterval(86400 * 180), emoji: "🛡️", isCompleted: false, completedDate: nil, monthlyContribution: 400),
        Goal(id: UUID(), title: "New MacBook", targetAmount: 2499, currentAmount: 2499, category: .gadget, targetDate: Date().addingTimeInterval(-86400 * 10), emoji: "💻", isCompleted: true, completedDate: Date().addingTimeInterval(-86400 * 10), monthlyContribution: 250),
        Goal(id: UUID(), title: "Car Down Payment", targetAmount: 8000, currentAmount: 1200, category: .car, targetDate: Date().addingTimeInterval(86400 * 365), emoji: "🚗", isCompleted: false, completedDate: nil, monthlyContribution: 600),
    ]
}
