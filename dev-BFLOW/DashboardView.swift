import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var notificationService: NotificationService
    @StateObject private var vm = DashboardViewModel()
    @State private var showingAllTransactions = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appSurface.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        headerSection
                        balanceCardSection
                        quickStatsSection
                        spendingRingSection
                        recentTransactionsSection
                    }
                    .padding(.horizontal, AppTheme.horizontalPadding)
                    .padding(.top, 16)
                    .padding(.bottom, 100)
                }

                // Notification banner
                if vm.showingNotificationBanner {
                    VStack {
                        notificationBanner
                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(10)
                }
            }
        }
        .onAppear { vm.updateGreeting() }
        .onReceive(notificationService.$parsedTransactions) { transactions in
            guard let latest = transactions.last else { return }
            vm.showNotification(for: latest)
        }
    }

    var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(vm.greeting + ",")
                    .font(.system(size: 16))
                    .foregroundColor(.textSecondary)
                Text(appViewModel.profile.name + ".")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.textPrimary)
            }
            Spacer()
            ZStack {
                Circle()
                    .fill(LinearGradient.brand)
                    .frame(width: 48, height: 48)
                Text(appViewModel.profile.avatarInitials)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }

    var balanceCardSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .fill(LinearGradient.cardDark)

            // Decorative circles
            Circle()
                .fill(.white.opacity(0.05))
                .frame(width: 180, height: 180)
                .offset(x: 120, y: -60)
            Circle()
                .fill(.white.opacity(0.04))
                .frame(width: 120, height: 120)
                .offset(x: -80, y: 60)

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Monthly Budget")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        Text("$\(String(format: "%.2f", appViewModel.monthlyBudget))")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Circle().fill(Color.successGreen)
                            Text("Active").font(.system(size: 12, weight: .medium)).foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(.white.opacity(0.15))
                        .clipShape(Capsule())
                    }
                }

                Spacer().frame(height: 16)

                MonthlyBudgetBar(
                    spent: appViewModel.totalSpentThisMonth,
                    upcoming: appViewModel.upcomingBillsAmount,
                    total: appViewModel.monthlyBudget
                )

                Spacer().frame(height: 14)

                HStack {
                    cardStat(label: "Spent", value: "$\(String(format: "%.0f", appViewModel.totalSpentThisMonth))", positive: false)
                    Spacer()
                    Rectangle().fill(.white.opacity(0.2)).frame(width: 1, height: 36)
                    Spacer()
                    cardStat(label: "Upcoming", value: "$\(String(format: "%.0f", appViewModel.upcomingBillsAmount))", positive: false)
                    Spacer()
                    Rectangle().fill(.white.opacity(0.2)).frame(width: 1, height: 36)
                    Spacer()
                    cardStat(label: "Remaining", value: "$\(String(format: "%.0f", appViewModel.budgetRemaining))", positive: true)
                }
            }
            .padding(24)
        }
        .frame(height: 200)
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 8)
    }

    func cardStat(label: String, value: String, positive: Bool) -> some View {
        VStack(alignment: .center, spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(positive ? .successGreen : Color(red: 1, green: 0.6, blue: 0.6))
        }
    }

    var quickStatsSection: some View {
        HStack(spacing: 12) {
            quickStatCard(icon: "chart.pie.fill", label: "Savings Rate", value: "\(Int(appViewModel.profile.savingsRate * 100))%", color: .successGreen)
            quickStatCard(icon: "arrow.up.circle.fill", label: "This Month", value: "$\(String(format: "%.0f", appViewModel.totalSpentThisMonth))", color: .brandOrange)
        }
    }

    func quickStatCard(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.system(size: 12)).foregroundColor(.textSecondary)
                Text(value).font(.system(size: 18, weight: .bold)).foregroundColor(.textPrimary)
            }
            Spacer()
        }
        .padding(16)
        .cardStyle()
    }

    var spendingRingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spending Breakdown")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.textPrimary)

            HStack(alignment: .center, spacing: 20) {
                SpendingDonutView(categories: appViewModel.spendingByCategory)
                    .frame(width: 120, height: 120)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(appViewModel.spendingByCategory.prefix(4), id: \.category) { item in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color(hex: item.category.color))
                                .frame(width: 8, height: 8)
                            Text(item.category.rawValue)
                                .font(.system(size: 12))
                                .foregroundColor(.textSecondary)
                                .lineLimit(1)
                            Spacer()
                            Text("$\(String(format: "%.0f", item.amount))")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.textPrimary)
                        }
                    }
                }
            }
            .padding(20)
            .cardStyle()
        }
    }

    var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Activity")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.textPrimary)
                Spacer()
                Button("See all") {
                    showingAllTransactions = true
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.brandOrange)
            }

            VStack(spacing: 8) {
                ForEach(appViewModel.transactions.prefix(5)) { transaction in
                    TransactionRowView(transaction: transaction)
                }
            }
        }
    }

    var notificationBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "bell.badge.fill")
                .foregroundColor(.brandOrange)
            VStack(alignment: .leading, spacing: 2) {
                Text("Bank Update").font(.system(size: 12, weight: .semibold))
                Text(vm.latestNotificationText).font(.system(size: 11)).foregroundColor(.textSecondary)
            }
            Spacer()
            Button("Add") {
                if let t = vm.latestTransaction {
                    appViewModel.addTransaction(t)
                }
                withAnimation { vm.showingNotificationBanner = false }
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.brandOrange)
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 4)
        .padding(.horizontal, 20)
        .padding(.top, 60)
    }
}

struct MonthlyBudgetBar: View {
    let spent: Double
    let upcoming: Double
    let total: Double

    @State private var appeared = false

    var spentFraction: CGFloat  { total > 0 ? CGFloat(min(spent / total, 1.0)) : 0 }
    var upcomingFraction: CGFloat {
        let remaining = max(total - spent, 0)
        return total > 0 ? CGFloat(min(upcoming / total, remaining / total)) : 0
    }
    var remainingFraction: CGFloat { max(1.0 - spentFraction - upcomingFraction, 0) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { geo in
                HStack(spacing: 2) {
                    // Spent — solid grey
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.35))
                        .frame(width: appeared ? geo.size.width * spentFraction : 0, height: 6)
                        .animation(.spring(response: 0.9, dampingFraction: 0.8).delay(0.1), value: appeared)

                    // Upcoming bills — lighter grey with dashed feel (slightly brighter)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.18))
                        .frame(width: appeared ? geo.size.width * upcomingFraction : 0, height: 6)
                        .animation(.spring(response: 0.9, dampingFraction: 0.8).delay(0.2), value: appeared)

                    // Remaining — green
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.successGreen.opacity(0.85))
                        .frame(width: appeared ? geo.size.width * remainingFraction : 0, height: 6)
                        .animation(.spring(response: 0.9, dampingFraction: 0.8).delay(0.3), value: appeared)
                }
            }
            .frame(height: 6)

            // Legend
            HStack(spacing: 14) {
                legendDot(color: .white.opacity(0.35), label: "Spent")
                legendDot(color: .white.opacity(0.55), label: "Bills due")
                legendDot(color: .successGreen, label: "Remaining")
            }
        }
        .onAppear { appeared = true }
    }

    func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 10, height: 4)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
        }
    }
}

struct SpendingDonutView: View {
    let categories: [(category: TransactionCategory, amount: Double)]
    @State private var animationProgress: CGFloat = 0

    var total: Double { categories.reduce(0) { $0 + $1.amount } }

    var body: some View {
        ZStack {
            ForEach(Array(slices.enumerated()), id: \.offset) { index, slice in
                Circle()
                    .trim(from: slice.start, to: slice.start + (slice.end - slice.start) * animationProgress)
                    .stroke(Color(hex: slice.color), style: StrokeStyle(lineWidth: 18, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            VStack(spacing: 0) {
                Text("$\(String(format: "%.0f", total))")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.textPrimary)
                Text("spent")
                    .font(.system(size: 10))
                    .foregroundColor(.textSecondary)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2)) { animationProgress = 1.0 }
        }
    }

    var slices: [(start: CGFloat, end: CGFloat, color: String)] {
        var result: [(start: CGFloat, end: CGFloat, color: String)] = []
        var currentStart: CGFloat = 0
        for item in categories.prefix(5) {
            let portion = total > 0 ? CGFloat(item.amount / total) : 0
            result.append((start: currentStart, end: currentStart + portion, color: item.category.color))
            currentStart += portion
        }
        return result
    }
}
