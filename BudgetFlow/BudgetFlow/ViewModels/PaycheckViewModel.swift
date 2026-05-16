import SwiftUI

class PaycheckViewModel: ObservableObject {
    @Published var paycheckInput: String = "3200"
    @Published var selectedRule: BudgetRule = .fiftyThirtyTwenty
    @Published var needsSlider: Double = 0.50
    @Published var wantsSlider: Double = 0.30
    @Published var savingsSlider: Double = 0.20
    @Published var selectedFrequency: PayFrequency = .biweekly
    @Published var showingRulePicker: Bool = false

    var paycheck: Double { Double(paycheckInput) ?? 0 }
    var needsAmount: Double { paycheck * needsSlider }
    var wantsAmount: Double { paycheck * wantsSlider }
    var savingsAmount: Double { paycheck * savingsSlider }

    func applyRule(_ rule: BudgetRule) {
        selectedRule = rule
        let splits = rule.splits
        needsSlider = splits.needs
        wantsSlider = splits.wants
        savingsSlider = splits.savings
    }

    func adjustSavings(_ delta: Double) {
        let newSavings = max(0, min(savingsSlider + delta, 1.0 - needsSlider - 0.05))
        let diff = newSavings - savingsSlider
        savingsSlider = newSavings
        wantsSlider -= diff
    }
}
