import SwiftUI

struct InsightsView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var vm = InsightsViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appSurface.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        headerSection
                        savingsProjectionSection
                        insightCardsSection
                        spendingTrendSection
                        smartTipsSection
                    }
                    .padding(.horizontal, AppTheme.horizontalPadding)
                    .padding(.top, 16)
                    .padding(.bottom, 100)
                }
            }
            .navigationBarHidden(true)
        }
    }

    var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Insights")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.textPrimary)
                Text("Your money, analyzed.")
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
            }
            Spacer()
            Picker("Period", selection: $vm.selectedPeriod) {
                ForEach(InsightsViewModel.InsightPeriod.allCases, id: \.self) { period in
                    Text(period.rawValue).tag(period)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 160)
        }
    }

    var savingsProjectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Savings Projection")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.textPrimary)

            let data = vm.projectionData(monthlySavings: appViewModel.savedThisMonth)

            VStack(spacing: 0) {
                // Chart bars
                HStack(alignment: .bottom, spacing: 10) {
                    ForEach(data, id: \.label) { point in
                        ProjectionBarView(label: point.label, amount: point.amount, maxAmount: data.map(\.amount).max() ?? 1)
                    }
                }
                .frame(height: 160)
                .padding(.horizontal, 8)

                Divider().padding(.top, 8)

                // Stats row
                HStack {
                    projectionStat(label: "Monthly", value: "$\(String(format: "%.0f", appViewModel.savedThisMonth))")
                    Divider().frame(height: 40)
                    projectionStat(label: "1 Year", value: "$\(String(format: "%.0f", data[2].amount))")
                    Divider().frame(height: 40)
                    projectionStat(label: "5 Years", value: "$\(String(format: "%.0f", data[4].amount))")
                }
                .padding(.top, 12)
            }
            .padding(20)
            .cardStyle()

            Text("Projection assumes 4.5% annual return on savings")
                .font(.system(size: 11))
                .foregroundColor(.textSecondary)
                .padding(.horizontal, 4)
        }
    }

    func projectionStat(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.system(size: 16, weight: .bold)).foregroundColor(.textPrimary)
            Text(label).font(.system(size: 11)).foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    var insightCardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Key Insights")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.textPrimary)

            ForEach(appViewModel.insights) { insight in
                InsightCardView(insight: insight)
            }
        }
    }

    var spendingTrendSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Budget vs Actual")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.textPrimary)

            VStack(spacing: 0) {
                ForEach(Array(budgetRows.enumerated()), id: \.element.category) { index, item in
                    CategoryBudgetRow(
                        category: item.category,
                        spent: item.spent,
                        budget: item.budget
                    )
                    if index < budgetRows.count - 1 {
                        Divider().padding(.horizontal, 16)
                    }
                }
            }
            .cardStyle()
        }
    }

    // Merge all budgeted categories, inserting zero-spend ones so every row is visible
    private var budgetRows: [(category: TransactionCategory, spent: Double, budget: Double)] {
        let budgetedCategories: [TransactionCategory] = [
            .food, .transport, .shopping, .entertainment, .bills, .health, .other
        ]
        return budgetedCategories.compactMap { cat in
            let budget = appViewModel.budgetFor(category: cat)
            guard budget > 0 else { return nil }
            let spent = appViewModel.spendingByCategory.first(where: { $0.category == cat })?.amount ?? 0
            return (category: cat, spent: spent, budget: budget)
        }
        .sorted { $0.budget > $1.budget }
    }

    var smartTipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles").foregroundColor(.brandAmber)
                Text("Smart Tips for You")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.textPrimary)
            }

            VStack(spacing: 10) {
                smartTip(icon: "cup.and.saucer.fill", color: .brandOrange, text: "Cutting $5 coffee daily adds up to $1,825/year in savings.")
                smartTip(icon: "cart.fill", color: .brandRed, text: "Grocery budgeting with a list can reduce spending by 23%.")
                smartTip(icon: "repeat.circle.fill", color: Color(hex: "9B59B6"), text: "You have 6 subscriptions. Review unused ones to save ~$47/mo.")
            }
        }
    }

    func smartTip(icon: String, color: Color, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 36)
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(16)
        .background(color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct CategoryBudgetRow: View {
    let category: TransactionCategory
    let spent: Double
    let budget: Double

    @State private var appeared = false

    var delta: Double { budget - spent }
    var progress: CGFloat { budget > 0 ? CGFloat(min(spent / budget, 1.0)) : 0 }

    // Over budget
    var isOver: Bool { delta < -0.005 }
    // Exactly zero remaining (within 50 cents rounding)
    var isExact: Bool { !isOver && abs(delta) < 0.50 }
    // Surplus
    var isSurplus: Bool { !isOver && !isExact }

    var deltaColor: Color {
        if isOver    { return .brandRed }
        if isExact   { return .textSecondary }
        return .successGreen
    }

    var deltaIcon: String {
        if isOver  { return "arrow.down" }
        if isExact { return "equal" }
        return "arrow.up"
    }

    var deltaText: String {
        if isExact { return "$0" }
        return "$\(String(format: "%.0f", abs(delta)))"
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                // Category icon
                ZStack {
                    Circle()
                        .fill(Color(hex: category.color).opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: category.icon)
                        .foregroundColor(Color(hex: category.color))
                        .font(.system(size: 17))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(category.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    Text("$\(String(format: "%.0f", spent)) of $\(String(format: "%.0f", budget))")
                        .font(.system(size: 11))
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                // Delta indicator
                HStack(spacing: 3) {
                    Image(systemName: deltaIcon)
                        .font(.system(size: 10, weight: .bold))
                    Text(deltaText)
                        .font(.system(size: 14, weight: .bold))
                        .contentTransition(.numericText())
                }
                .foregroundColor(deltaColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(deltaColor.opacity(0.10))
                .clipShape(Capsule())
            }

            // Progress bar — fills toward budget; turns red when over
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: category.color).opacity(0.10))
                        .frame(height: 5)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            isOver
                                ? LinearGradient(colors: [.brandOrange, .brandRed], startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(colors: [Color(hex: category.color)], startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(width: appeared ? geo.size.width * progress : 0, height: 5)
                        .animation(.spring(response: 0.8, dampingFraction: 0.78).delay(0.05), value: appeared)
                }
            }
            .frame(height: 5)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .onAppear { appeared = true }
    }
}

struct ProjectionBarView: View {
    let label: String
    let amount: Double
    let maxAmount: Double
    @State private var appeared = false

    var barHeight: CGFloat {
        maxAmount > 0 ? CGFloat(amount / maxAmount) * 130 : 0
    }

    var body: some View {
        VStack(spacing: 6) {
            Text("$\(amount >= 1000 ? String(format: "%.0fk", amount/1000) : String(format: "%.0f", amount))")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.textSecondary)
                .lineLimit(1)
            Spacer()
            RoundedRectangle(cornerRadius: 6)
                .fill(LinearGradient.brand)
                .frame(width: 28, height: appeared ? barHeight : 0)
                .animation(.spring(response: 0.8, dampingFraction: 0.75).delay(0.1), value: appeared)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .onAppear { appeared = true }
    }
}

struct InsightCardView: View {
    let insight: Insight

    var cardColor: Color {
        switch insight.type {
        case .tip: return .brandOrange
        case .warning: return .brandRed
        case .achievement: return .successGreen
        case .projection: return Color(hex: "4A90E2")
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle().fill(cardColor.opacity(0.15)).frame(width: 44, height: 44)
                Image(systemName: insight.icon).font(.system(size: 20)).foregroundColor(cardColor)
            }
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(insight.title).font(.system(size: 14, weight: .bold)).foregroundColor(.textPrimary)
                    Spacer()
                    Text(insight.type.rawValue)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(cardColor)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(cardColor.opacity(0.12))
                        .clipShape(Capsule())
                }
                Text(insight.description)
                    .font(.system(size: 12))
                    .foregroundColor(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let impact = insight.savingsImpact {
                    Text("Potential save: $\(String(format: "%.0f", impact))/yr")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.successGreen)
                }
                if let action = insight.actionLabel {
                    Button(action: {}) {
                        Text(action)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(cardColor)
                    }
                }
            }
        }
        .padding(16)
        .cardStyle()
    }
}
