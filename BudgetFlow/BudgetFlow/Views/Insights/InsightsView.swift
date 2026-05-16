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
            Text("Spending by Category")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.textPrimary)

            VStack(spacing: 12) {
                ForEach(appViewModel.spendingByCategory.prefix(5), id: \.category) { item in
                    let total = appViewModel.totalSpentThisMonth
                    let pct = total > 0 ? item.amount / total : 0
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(Color(hex: item.category.color).opacity(0.15)).frame(width: 40, height: 40)
                            Image(systemName: item.category.icon)
                                .foregroundColor(Color(hex: item.category.color))
                                .font(.system(size: 18))
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(item.category.rawValue).font(.system(size: 14, weight: .semibold)).foregroundColor(.textPrimary)
                                Spacer()
                                Text("$\(String(format: "%.0f", item.amount))").font(.system(size: 14, weight: .bold)).foregroundColor(.textPrimary)
                            }
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4).fill(Color(hex: item.category.color).opacity(0.12)).frame(height: 6)
                                    RoundedRectangle(cornerRadius: 4).fill(Color(hex: item.category.color)).frame(width: geo.size.width * pct, height: 6)
                                }
                            }
                            .frame(height: 6)
                        }
                    }
                }
            }
            .padding(20)
            .cardStyle()
        }
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
