import SwiftUI

class InsightsViewModel: ObservableObject {
    @Published var selectedPeriod: InsightPeriod = .month
    @Published var showingProjectionDetail: Bool = false

    enum InsightPeriod: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
    }

    func savingsProjection(monthlyAmount: Double, months: Int, annualRate: Double = 0.045) -> Double {
        let monthlyRate = annualRate / 12
        if monthlyRate == 0 { return monthlyAmount * Double(months) }
        return monthlyAmount * ((pow(1 + monthlyRate, Double(months)) - 1) / monthlyRate)
    }

    func projectionData(monthlySavings: Double) -> [(label: String, amount: Double)] {
        [
            ("3 mo", savingsProjection(monthlyAmount: monthlySavings, months: 3)),
            ("6 mo", savingsProjection(monthlyAmount: monthlySavings, months: 6)),
            ("1 yr", savingsProjection(monthlyAmount: monthlySavings, months: 12)),
            ("2 yr", savingsProjection(monthlyAmount: monthlySavings, months: 24)),
            ("5 yr", savingsProjection(monthlyAmount: monthlySavings, months: 60)),
        ]
    }
}
