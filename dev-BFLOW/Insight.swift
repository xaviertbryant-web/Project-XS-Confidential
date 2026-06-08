import Foundation

enum InsightType: String {
    case tip = "Tip"
    case warning = "Warning"
    case achievement = "Achievement"
    case projection = "Projection"
}

struct Insight: Identifiable {
    let id: UUID
    var title: String
    var description: String
    var type: InsightType
    var icon: String
    var actionLabel: String?
    var savingsImpact: Double?

    static let sampleData: [Insight] = [
        Insight(id: UUID(), title: "Cut your coffee spend 🔥", description: "You've spent $98 on coffee this month. Brewing at home could save you $74/month — that's $888/year!", type: .tip, icon: "cup.and.saucer.fill", actionLabel: "Add to Goal", savingsImpact: 888),
        Insight(id: UUID(), title: "On track this month", description: "Your spending is 12% lower than last month. Keep it up!", type: .achievement, icon: "chart.line.downtrend.xyaxis", actionLabel: nil, savingsImpact: nil),
        Insight(id: UUID(), title: "Subscription audit needed", description: "You have 6 active subscriptions totalling $94.94/month. Consider reviewing them.", type: .warning, icon: "exclamationmark.circle.fill", actionLabel: "Review", savingsImpact: 94.94),
        Insight(id: UUID(), title: "Japan Trip projection", description: "At your current saving rate, you'll hit your Japan goal in 3 months — 2 weeks ahead of schedule!", type: .projection, icon: "airplane", actionLabel: nil, savingsImpact: nil),
    ]
}

struct SpendingProjection {
    var month: String
    var projected: Double
    var actual: Double?
}
