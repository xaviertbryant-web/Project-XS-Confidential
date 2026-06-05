import SwiftUI

// MARK: - Main view

struct PaycheckView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var notificationService: NotificationService
    @State private var expandedBucket: BudgetBucket? = .needs
    @State private var showingAddFixedCost = false
    @State private var editingFixedCost: FixedCost? = nil
    @State private var showingAddSubscription = false
    @State private var editingSubscription: FixedCost? = nil
    @State private var addingToBucket: BudgetBucket? = nil
    @State private var editingSubCat: BudgetSubCategory? = nil
    @FocusState private var paycheckFocused: Bool
    @State private var paycheckInput: String = "3200"
    @State private var selectedFrequency: PayFrequency = .biweekly

    private var budget: PaycheckBudget { appViewModel.paycheckBudget }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appSurface.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        headerSection
                        incomeSummaryCard
                        budgetAllocationHeader
                        ForEach(BudgetBucket.allCases, id: \.self) { bucket in
                            BucketCardView(
                                bucket: bucket,
                                isExpanded: expandedBucket == bucket,
                                subCategories: budget.subCategories.filter { $0.bucket == bucket },
                                monthlyIncome: budget.monthlyIncome,
                                onToggle: {
                                    withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                                        expandedBucket = expandedBucket == bucket ? nil : bucket
                                    }
                                },
                                onAdd: { addingToBucket = bucket },
                                onEdit: { editingSubCat = $0 },
                                onDelete: { id in
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        appViewModel.paycheckBudget.subCategories.removeAll { $0.id == id }
                                    }
                                },
                                onAmountChange: { id, amt in
                                    if let i = appViewModel.paycheckBudget.subCategories.firstIndex(where: { $0.id == id }) {
                                        appViewModel.paycheckBudget.subCategories[i].monthlyAmount = amt
                                    }
                                },
                                onQuickAdd: { name, emoji, amount in
                                    let sub = BudgetSubCategory(id: UUID(), name: name, emoji: emoji, monthlyAmount: amount, bucket: bucket)
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        appViewModel.paycheckBudget.subCategories.append(sub)
                                    }
                                    expandedBucket = bucket
                                }
                            )
                        }
                        allocationFooter
                        subscriptionsSection
                        fixedCostsSummaryCard
                        bankNotificationSection
                    }
                    .padding(.horizontal, AppTheme.horizontalPadding)
                    .padding(.top, 16)
                    .padding(.bottom, 100)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            paycheckInput = String(format: "%.0f", budget.paycheckAmount)
            selectedFrequency = budget.frequency
        }
        .onChange(of: paycheckInput)      { _, _ in syncToApp() }
        .onChange(of: selectedFrequency)  { _, _ in syncToApp() }
        .sheet(isPresented: $showingAddFixedCost) {
            AddFixedCostSheet(existingCost: nil) { appViewModel.paycheckBudget.fixedCosts.append($0) }
        }
        .sheet(item: $editingFixedCost) { cost in
            AddFixedCostSheet(existingCost: cost) { updated in
                if let i = appViewModel.paycheckBudget.fixedCosts.firstIndex(where: { $0.id == updated.id }) {
                    appViewModel.paycheckBudget.fixedCosts[i] = updated
                }
            }
        }
        .sheet(isPresented: $showingAddSubscription) {
            AddSubscriptionSheet(existing: nil) { appViewModel.paycheckBudget.fixedCosts.append($0) }
        }
        .sheet(item: $editingSubscription) { sub in
            AddSubscriptionSheet(existing: sub) { updated in
                if let i = appViewModel.paycheckBudget.fixedCosts.firstIndex(where: { $0.id == updated.id }) {
                    appViewModel.paycheckBudget.fixedCosts[i] = updated
                }
            }
        }
        .sheet(item: $addingToBucket) { bucket in
            AddSubCategorySheet(bucket: bucket, existing: nil) { sub in
                appViewModel.paycheckBudget.subCategories.append(sub)
                expandedBucket = bucket
            }
        }
        .sheet(item: $editingSubCat) { sub in
            AddSubCategorySheet(bucket: sub.bucket, existing: sub) { updated in
                if let i = appViewModel.paycheckBudget.subCategories.firstIndex(where: { $0.id == updated.id }) {
                    appViewModel.paycheckBudget.subCategories[i] = updated
                }
            }
        }
    }

    private func syncToApp() {
        appViewModel.paycheckBudget.paycheckAmount = Double(paycheckInput) ?? budget.paycheckAmount
        appViewModel.paycheckBudget.frequency = selectedFrequency
    }

    // MARK: Header

    var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Budget Planner")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.textPrimary)
                Text("Design your monthly money plan")
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
            }
            Spacer()
        }
    }

    // MARK: Income summary card

    var incomeSummaryCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .fill(LinearGradient.cardDark)

            Circle().fill(.white.opacity(0.04)).frame(width: 160).offset(x: 110, y: -50)
            Circle().fill(.white.opacity(0.03)).frame(width: 100).offset(x: -80, y: 50)

            VStack(alignment: .leading, spacing: 16) {
                // Paycheck input row
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Paycheck").font(.system(size: 12, weight: .medium)).foregroundColor(.white.opacity(0.6))
                        HStack(alignment: .firstTextBaseline, spacing: 3) {
                            Text("$").font(.system(size: 22, weight: .bold)).foregroundColor(.brandOrange)
                            TextField("0", text: $paycheckInput)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                                .keyboardType(.decimalPad)
                                .focused($paycheckFocused)
                                .frame(maxWidth: 160)
                        }
                    }
                    Spacer()
                    Picker("", selection: $selectedFrequency) {
                        ForEach(PayFrequency.allCases, id: \.self) { f in
                            Text(f.rawValue).tag(f)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(.white.opacity(0.12))
                    .clipShape(Capsule())
                    .foregroundColor(.white)
                }

                // Monthly breakdown bar
                VStack(spacing: 6) {
                    incomeAllocationBar
                    HStack {
                        incomeBarLegend(color: Color(hex: "4A90E2"), label: "Fixed")
                        Spacer()
                        incomeBarLegend(color: .brandOrange, label: "Needs")
                        Spacer()
                        incomeBarLegend(color: .brandRed, label: "Wants")
                        Spacer()
                        incomeBarLegend(color: .successGreen, label: "Savings")
                        Spacer()
                        incomeBarLegend(color: .white.opacity(0.25), label: "Free")
                    }
                }

                // Monthly income figure
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Monthly Income").font(.system(size: 11)).foregroundColor(.white.opacity(0.6))
                        Text("$\(String(format: "%.2f", budget.monthlyIncome))").font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                    }
                    Spacer()
                    Rectangle().fill(.white.opacity(0.2)).frame(width: 1, height: 32)
                    Spacer()
                    VStack(alignment: .center, spacing: 2) {
                        Text("Fixed Costs").font(.system(size: 11)).foregroundColor(.white.opacity(0.6))
                        Text("$\(String(format: "%.2f", budget.totalFixedCosts))").font(.system(size: 15, weight: .bold)).foregroundColor(Color(hex: "4A90E2"))
                    }
                    Spacer()
                    Rectangle().fill(.white.opacity(0.2)).frame(width: 1, height: 32)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Discretionary").font(.system(size: 11)).foregroundColor(.white.opacity(0.6))
                        Text("$\(String(format: "%.2f", budget.discretionaryIncome))").font(.system(size: 15, weight: .bold)).foregroundColor(.successGreen)
                    }
                }
            }
            .padding(22)
        }
        .shadow(color: .black.opacity(0.18), radius: 20, x: 0, y: 8)
    }

    @State private var barAppeared = false

    var incomeAllocationBar: some View {
        GeometryReader { geo in
            HStack(spacing: 2) {
                let total = budget.monthlyIncome
                let fixed   = total > 0 ? CGFloat(budget.totalFixedCosts / total) : 0
                let needs   = total > 0 ? CGFloat(budget.subCategoryTotal(for: .needs) / total) : 0
                let wants   = total > 0 ? CGFloat(budget.subCategoryTotal(for: .wants) / total) : 0
                let savings = total > 0 ? CGFloat(budget.subCategoryTotal(for: .savings) / total) : 0
                let free    = max(1 - fixed - needs - wants - savings, 0)
                let w       = geo.size.width

                RoundedRectangle(cornerRadius: 4).fill(Color(hex: "4A90E2")).frame(width: barAppeared ? w * fixed : 0, height: 8)
                RoundedRectangle(cornerRadius: 4).fill(Color.brandOrange).frame(width: barAppeared ? w * needs : 0, height: 8)
                RoundedRectangle(cornerRadius: 4).fill(Color.brandRed).frame(width: barAppeared ? w * wants : 0, height: 8)
                RoundedRectangle(cornerRadius: 4).fill(Color.successGreen).frame(width: barAppeared ? w * savings : 0, height: 8)
                if free > 0 {
                    RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.2)).frame(width: barAppeared ? w * free : 0, height: 8)
                }
            }
            .animation(.spring(response: 0.9, dampingFraction: 0.8).delay(0.1), value: barAppeared)
        }
        .frame(height: 8)
        .onAppear { barAppeared = true }
    }

    func incomeBarLegend(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 10, height: 4)
            Text(label).font(.system(size: 9, weight: .medium)).foregroundColor(.white.opacity(0.55))
        }
    }

    // MARK: Budget allocation header

    var budgetAllocationHeader: some View {
        HStack {
            Text("Budget Allocation")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.textPrimary)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                let alloc = budget.totalFixedCosts + budget.totalSubCategoryAllocation
                Text("$\(String(format: "%.0f", alloc)) allocated")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.textSecondary)
                Text("of $\(String(format: "%.0f", budget.monthlyIncome))/mo")
                    .font(.system(size: 11))
                    .foregroundColor(.textSecondary)
            }
        }
    }

    // MARK: Allocation footer

    var allocationFooter: some View {
        let over = budget.isOverAllocated
        let amount = over
            ? abs(budget.monthlyIncome - budget.totalFixedCosts - budget.totalSubCategoryAllocation)
            : budget.unallocated

        return HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(over ? Color.brandRed.opacity(0.12) : Color.successGreen.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: over ? "exclamationmark.triangle.fill" : "checkmark.seal.fill")
                    .font(.system(size: 20))
                    .foregroundColor(over ? .brandRed : .successGreen)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(over ? "Over-allocated" : "Unallocated funds")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.textPrimary)
                Text(over
                    ? "You've planned $\(String(format: "%.0f", amount)) more than your income."
                    : "$\(String(format: "%.0f", amount)) is unassigned — assign it or keep as buffer.")
                    .font(.system(size: 12))
                    .foregroundColor(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(16)
        .background(over ? Color.brandRed.opacity(0.06) : Color.successGreen.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: Subscriptions section

    private var subscriptionCosts: [FixedCost] { budget.fixedCosts.filter { $0.category == .subscriptions } }
    private var totalSubscriptionsMonthly: Double { subscriptionCosts.reduce(0) { $0 + $1.monthlyEquivalent } }

    var subscriptionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 8) {
                    ZStack {
                        Circle().fill(Color(hex: "9B59B6").opacity(0.12)).frame(width: 34, height: 34)
                        Image(systemName: "repeat.circle.fill")
                            .foregroundColor(Color(hex: "9B59B6"))
                            .font(.system(size: 18))
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Subscriptions")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.textPrimary)
                        Text("Recurring services")
                            .font(.system(size: 11))
                            .foregroundColor(.textSecondary)
                    }
                }
                Spacer()
                Button { showingAddSubscription = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color(hex: "9B59B6"))
                }
            }

            if subscriptionCosts.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles").foregroundColor(Color(hex: "9B59B6").opacity(0.5)).font(.system(size: 18))
                    Text("No subscriptions added yet.")
                        .font(.system(size: 13)).foregroundColor(.textSecondary)
                }
                .padding(.vertical, 4)
            } else {
                ForEach(subscriptionCosts) { sub in
                    HStack(spacing: 12) {
                        Text(sub.emoji).font(.system(size: 20))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(sub.name)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.textPrimary)
                            if sub.billingCycle != .monthly {
                                Text(sub.billingCycle.rawValue)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(Color(hex: "9B59B6"))
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(Color(hex: "9B59B6").opacity(0.10))
                                    .clipShape(Capsule())
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("$\(String(format: "%.2f", sub.monthlyEquivalent))/mo")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.textPrimary)
                            if sub.billingCycle != .monthly {
                                Text("$\(String(format: "%.2f", sub.amount)) billed \(sub.billingCycle.shortLabel)")
                                    .font(.system(size: 10))
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        Button { editingSubscription = sub } label: {
                            Image(systemName: "pencil")
                                .font(.system(size: 12))
                                .foregroundColor(.textSecondary)
                        }
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                appViewModel.paycheckBudget.fixedCosts.removeAll { $0.id == sub.id }
                            }
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 12))
                                .foregroundColor(.brandRed.opacity(0.7))
                        }
                    }
                    if sub.id != subscriptionCosts.last?.id {
                        Divider().padding(.leading, 44)
                    }
                }

                Divider()

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Total subscriptions")
                            .font(.system(size: 12)).foregroundColor(.textSecondary)
                        Text("$\(String(format: "%.2f", totalSubscriptionsMonthly * 12)) / year")
                            .font(.system(size: 11)).foregroundColor(.textSecondary)
                    }
                    Spacer()
                    Text("$\(String(format: "%.2f", totalSubscriptionsMonthly)) / mo")
                        .font(.system(size: 15, weight: .bold)).foregroundColor(Color(hex: "9B59B6"))
                }

                if subscriptionCosts.count >= 3 {
                    HStack(spacing: 8) {
                        Image(systemName: "lightbulb.fill").foregroundColor(.brandAmber).font(.system(size: 13))
                        Text("You have \(subscriptionCosts.count) subscriptions. Cancelling unused ones could save $\(String(format: "%.0f", totalSubscriptionsMonthly * 0.3))+/mo.")
                            .font(.system(size: 12)).foregroundColor(.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(12)
                    .background(Color.brandAmber.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(20)
        .cardStyle()
    }

    // MARK: Fixed costs compact card

    private var nonSubscriptionCosts: [FixedCost] { budget.fixedCosts.filter { $0.category != .subscriptions } }
    private var totalNonSubscriptionCosts: Double { nonSubscriptionCosts.reduce(0) { $0 + $1.monthlyEquivalent } }

    var fixedCostsSummaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.repeat.circle.fill")
                        .foregroundColor(Color(hex: "4A90E2"))
                        .font(.system(size: 18))
                    Text("Fixed Monthly Costs")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.textPrimary)
                }
                Spacer()
                Button { showingAddFixedCost = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(LinearGradient.brand)
                }
            }

            // Compact rows — subscriptions managed separately above
            ForEach(nonSubscriptionCosts) { cost in
                HStack(spacing: 12) {
                    Text(cost.emoji).font(.system(size: 18))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(cost.name)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.textPrimary)
                        if cost.billingCycle != .monthly {
                            Text("$\(String(format: "%.2f", cost.amount))\(cost.billingCycle.shortLabel)")
                                .font(.system(size: 10))
                                .foregroundColor(.textSecondary)
                        }
                    }
                    Spacer()
                    Text("$\(String(format: "%.2f", cost.monthlyEquivalent))/mo")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.textPrimary)
                    Button { editingFixedCost = cost } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 12))
                            .foregroundColor(.textSecondary)
                    }
                    Button {
                        withAnimation { appViewModel.paycheckBudget.fixedCosts.removeAll { $0.id == cost.id } }
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundColor(.brandRed.opacity(0.7))
                    }
                }
            }

            if nonSubscriptionCosts.isEmpty {
                Text("No fixed costs yet. Tap + to add recurring bills.")
                    .font(.system(size: 13))
                    .foregroundColor(.textSecondary)
            }

            Divider()
            HStack {
                Text("Total committed")
                    .font(.system(size: 13)).foregroundColor(.textSecondary)
                Spacer()
                Text("$\(String(format: "%.2f", totalNonSubscriptionCosts)) / mo")
                    .font(.system(size: 14, weight: .bold)).foregroundColor(Color(hex: "4A90E2"))
            }
        }
        .padding(20)
        .cardStyle()
    }

    // MARK: Bank notifications

    var bankNotificationSection: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(Color.brandOrange.opacity(0.12)).frame(width: 44, height: 44)
                Image(systemName: "bell.badge.fill").foregroundColor(.brandOrange).font(.system(size: 20))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("Bank Notifications")
                    .font(.system(size: 15, weight: .semibold)).foregroundColor(.textPrimary)
                Text(notificationService.permissionGranted
                    ? "Active — auto-tracking transactions"
                    : "Enable to auto-detect your spending")
                    .font(.system(size: 12)).foregroundColor(.textSecondary)
            }
            Spacer()
            if notificationService.permissionGranted {
                Image(systemName: "checkmark.circle.fill").foregroundColor(.successGreen).font(.system(size: 22))
            } else {
                Button {
                    Task { await notificationService.requestPermission() }
                } label: {
                    Text("Enable")
                        .font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(LinearGradient.brand)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(16)
        .cardStyle()
    }
}

// MARK: - Bucket card

struct BucketCardView: View {
    let bucket: BudgetBucket
    let isExpanded: Bool
    let subCategories: [BudgetSubCategory]
    let monthlyIncome: Double
    let onToggle: () -> Void
    let onAdd: () -> Void
    let onEdit: (BudgetSubCategory) -> Void
    let onDelete: (UUID) -> Void
    let onAmountChange: (UUID, Double) -> Void
    let onQuickAdd: (String, String, Double) -> Void

    @State private var editingId: UUID? = nil
    @State private var editText: String = ""
    @FocusState private var editFocused: Bool

    private var bucketColor: Color { Color(hex: bucket.colorHex) }
    private var bucketTotal: Double { subCategories.reduce(0) { $0 + $1.monthlyAmount } }
    private var bucketPct: Double { monthlyIncome > 0 ? bucketTotal / monthlyIncome * 100 : 0 }

    // Already-added names (to filter from suggestions)
    private var addedNames: Set<String> { Set(subCategories.map { $0.name.lowercased() }) }

    var body: some View {
        VStack(spacing: 0) {
            // Header — always visible
            headerRow
                .padding(18)
                .contentShape(Rectangle())
                .onTapGesture { onToggle() }

            if isExpanded {
                VStack(spacing: 0) {
                    Divider().padding(.horizontal, 18)
                    subCategoryList
                    Divider().padding(.horizontal, 18)
                    suggestionsRow
                    addCustomRow
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
        .shadow(color: AppTheme.cardShadowColor, radius: AppTheme.cardShadowRadius, x: 0, y: AppTheme.cardShadowY)
        .overlay(alignment: .top) {
            // Thin colored top accent bar
            RoundedRectangle(cornerRadius: 4)
                .fill(bucketColor)
                .frame(height: 4)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
                .padding(.top, 0)
        }
    }

    var headerRow: some View {
        HStack(spacing: 14) {
            // Icon circle
            ZStack {
                Circle()
                    .fill(bucketColor.opacity(0.12))
                    .frame(width: 46, height: 46)
                Text(bucket.emoji).font(.system(size: 22))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(bucket.rawValue)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.textPrimary)
                Text(bucket.tagline)
                    .font(.system(size: 11))
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("$\(String(format: "%.0f", bucketTotal))")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(bucketColor)
                Text("\(String(format: "%.0f", bucketPct))% of income")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.textSecondary)
            }

            Image(systemName: "chevron.down")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.textSecondary)
                .rotationEffect(.degrees(isExpanded ? 180 : 0))
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isExpanded)
        }
    }

    var subCategoryList: some View {
        VStack(spacing: 0) {
            if subCategories.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle.dashed")
                        .foregroundColor(.textSecondary.opacity(0.4))
                        .font(.system(size: 22))
                    Text("No categories yet. Add from suggestions below.")
                        .font(.system(size: 13))
                        .foregroundColor(.textSecondary)
                }
                .padding(18)
            } else {
                ForEach(subCategories) { sub in
                    subCategoryRow(sub)
                    if sub.id != subCategories.last?.id {
                        Divider().padding(.leading, 68)
                    }
                }
            }
        }
    }

    func subCategoryRow(_ sub: BudgetSubCategory) -> some View {
        HStack(spacing: 14) {
            // Emoji
            ZStack {
                Circle()
                    .fill(bucketColor.opacity(0.10))
                    .frame(width: 38, height: 38)
                Text(sub.emoji).font(.system(size: 18))
            }

            // Name
            VStack(alignment: .leading, spacing: 2) {
                Text(sub.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textPrimary)
                Text("\(String(format: "%.1f", monthlyIncome > 0 ? sub.monthlyAmount / monthlyIncome * 100 : 0))% of income")
                    .font(.system(size: 10))
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            // Amount — tap to inline-edit
            if editingId == sub.id {
                HStack(spacing: 3) {
                    Text("$").font(.system(size: 15, weight: .bold)).foregroundColor(bucketColor)
                    TextField("0", text: $editText)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(bucketColor)
                        .keyboardType(.decimalPad)
                        .focused($editFocused)
                        .frame(width: 70)
                        .multilineTextAlignment(.trailing)
                        .onSubmit { commitEdit(sub) }
                }
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(bucketColor.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 10))

                Button {
                    commitEdit(sub)
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(bucketColor)
                        .font(.system(size: 22))
                }
            } else {
                Button {
                    editText = String(format: "%.0f", sub.monthlyAmount)
                    editingId = sub.id
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { editFocused = true }
                } label: {
                    Text("$\(String(format: "%.0f", sub.monthlyAmount))")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(bucketColor)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(bucketColor.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }

            // Edit full details
            Button { onEdit(sub) } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 13))
                    .foregroundColor(.textSecondary.opacity(0.7))
                    .frame(width: 28, height: 28)
            }

            // Delete
            Button {
                onDelete(sub.id)
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.brandRed.opacity(0.6))
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }

    private func commitEdit(_ sub: BudgetSubCategory) {
        if let val = Double(editText), val >= 0 {
            onAmountChange(sub.id, val)
        }
        editingId = nil
        editFocused = false
    }

    // Horizontal chip row — filters out already-added categories
    var suggestionsRow: some View {
        let remaining = bucket.suggestions.filter { !addedNames.contains($0.name.lowercased()) }
        return VStack(alignment: .leading, spacing: 10) {
            if !remaining.isEmpty {
                Text("Quick add")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.textSecondary)
                    .padding(.horizontal, 18)
                    .padding(.top, 14)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(remaining, id: \.name) { suggestion in
                            Button {
                                onQuickAdd(suggestion.name, suggestion.emoji, suggestion.amount)
                            } label: {
                                HStack(spacing: 6) {
                                    Text(suggestion.emoji).font(.system(size: 15))
                                    Text(suggestion.name)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(bucketColor)
                                    Text("~$\(String(format: "%.0f", suggestion.amount))")
                                        .font(.system(size: 11))
                                        .foregroundColor(.textSecondary)
                                }
                                .padding(.horizontal, 12).padding(.vertical, 8)
                                .background(bucketColor.opacity(0.08))
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(bucketColor.opacity(0.2), lineWidth: 1))
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                }
                .padding(.bottom, 4)
            }
        }
    }

    var addCustomRow: some View {
        Button { onAdd() } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(bucketColor)
                Text("Add custom category")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(bucketColor)
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
        }
    }
}

// MARK: - Add / Edit sub-category sheet

struct AddSubCategorySheet: View {
    let bucket: BudgetBucket
    let existing: BudgetSubCategory?
    let onSave: (BudgetSubCategory) -> Void

    @Environment(\.dismiss) var dismiss
    @State private var name: String = ""
    @State private var amountText: String = ""
    @State private var emoji: String = "📌"
    @FocusState private var amountFocused: Bool

    private var bucketColor: Color { Color(hex: bucket.colorHex) }
    private var isEditing: Bool { existing != nil }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Bucket badge
                    HStack(spacing: 8) {
                        Text(bucket.emoji).font(.system(size: 20))
                        Text(bucket.rawValue)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(bucketColor)
                        Text("·")
                            .foregroundColor(.textSecondary)
                        Text(bucket.tagline)
                            .font(.system(size: 13))
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(bucketColor.opacity(0.08))
                    .clipShape(Capsule())
                    .padding(.top, 8)

                    // Big amount input
                    VStack(spacing: 4) {
                        Text("Monthly Amount")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.textSecondary)
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("$")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(bucketColor)
                            TextField("0", text: $amountText)
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.textPrimary)
                                .keyboardType(.decimalPad)
                                .focused($amountFocused)
                                .multilineTextAlignment(.center)
                        }
                    }

                    // Name + emoji
                    VStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Label").font(.system(size: 12, weight: .semibold)).foregroundColor(.textSecondary)
                            HStack(spacing: 10) {
                                Text(emoji).font(.system(size: 24)).frame(width: 44)
                                TextField("e.g. Groceries", text: $name)
                                    .font(.system(size: 16))
                                    .padding(14)
                                    .background(Color.appSurface)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }

                        // Emoji picker
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Icon").font(.system(size: 12, weight: .semibold)).foregroundColor(.textSecondary)
                            let emojis = bucket.suggestions.map(\.emoji) + ["📌","⭐","🔖","💡","🧾","🪙","🎯","🔑"]
                            let unique = Array(NSOrderedSet(array: emojis)) as! [String]
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                                ForEach(unique, id: \.self) { e in
                                    Button { emoji = e } label: {
                                        Text(e).font(.system(size: 22))
                                            .frame(width: 40, height: 40)
                                            .background(emoji == e ? bucketColor.opacity(0.15) : Color.appSurface)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(emoji == e ? bucketColor : Color.clear, lineWidth: 1.5))
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                    .cardStyle()

                    PrimaryButton(title: isEditing ? "Save Changes" : "Add to \(bucket.rawValue)") {
                        guard !name.isEmpty, let amount = Double(amountText), amount > 0 else { return }
                        let sub = BudgetSubCategory(id: existing?.id ?? UUID(), name: name, emoji: emoji, monthlyAmount: amount, bucket: bucket)
                        onSave(sub)
                        dismiss()
                    }
                    .padding(.horizontal, 4)
                    .disabled(name.isEmpty || (Double(amountText) ?? 0) <= 0)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .navigationTitle(isEditing ? "Edit Category" : "New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(bucketColor)
                }
            }
            .onAppear {
                if let e = existing {
                    name = e.name; amountText = String(format: "%.0f", e.monthlyAmount); emoji = e.emoji
                } else {
                    amountFocused = true
                }
            }
        }
    }
}

// MARK: - Add / Edit Fixed Cost Sheet (keep existing)

struct AddFixedCostSheet: View {
    let existingCost: FixedCost?
    let onSave: (FixedCost) -> Void

    @Environment(\.dismiss) var dismiss
    @State private var name: String = ""
    @State private var amountText: String = ""
    @State private var category: FixedCostCategory = .other
    @State private var emoji: String = "📌"
    @State private var billingCycle: BillingCycle = .monthly
    @FocusState private var amountFocused: Bool

    private var isEditing: Bool { existingCost != nil }

    private let presets: [(name: String, amount: Double, category: FixedCostCategory, emoji: String)] = [
        ("Rent",1200,.housing,"🏠"),("Mortgage",1500,.housing,"🏡"),("Electric",90,.utilities,"⚡"),
        ("Gas",40,.utilities,"🔥"),("Internet",60,.utilities,"📡"),("Water",35,.utilities,"💧"),
        ("Car Insurance",120,.insurance,"🛡️"),("Health Ins.",180,.insurance,"🏥"),
        ("Phone Plan",45,.phone,"📱"),("Netflix",16,.subscriptions,"📺"),
        ("Spotify",11,.subscriptions,"🎵"),("Gym",40,.subscriptions,"💪"),
        ("Car Loan",320,.transport,"🚗"),("Transit Pass",90,.transport,"🚇"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    VStack(spacing: 4) {
                        Text("Monthly Amount").font(.system(size: 13, weight: .semibold)).foregroundColor(.textSecondary)
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("$").font(.system(size: 32, weight: .bold)).foregroundColor(.brandOrange)
                            TextField("0.00", text: $amountText)
                                .font(.system(size: 44, weight: .bold)).foregroundColor(.textPrimary)
                                .keyboardType(.decimalPad).focused($amountFocused).multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 8)

                    VStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Name").font(.system(size: 12, weight: .semibold)).foregroundColor(.textSecondary)
                            HStack(spacing: 10) {
                                Text(emoji).font(.system(size: 22))
                                TextField("e.g. Rent", text: $name)
                                    .font(.system(size: 16)).padding(14)
                                    .background(Color.appSurface).clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Category").font(.system(size: 12, weight: .semibold)).foregroundColor(.textSecondary)
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                                ForEach(FixedCostCategory.allCases, id: \.self) { cat in
                                    Button {
                                        category = cat
                                        if emoji == "📌" { emoji = cat.defaultEmoji }
                                    } label: {
                                        VStack(spacing: 4) {
                                            Text(cat.defaultEmoji).font(.system(size: 20))
                                            Text(cat.rawValue).font(.system(size: 9, weight: .medium))
                                                .foregroundColor(category == cat ? Color(hex: cat.color) : .textSecondary)
                                                .lineLimit(1).minimumScaleFactor(0.8)
                                        }
                                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                                        .background(category == cat ? Color(hex: cat.color).opacity(0.12) : Color.appSurface)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(category == cat ? Color(hex: cat.color) : Color.clear, lineWidth: 1.5))
                                    }
                                }
                            }
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Billing Cycle").font(.system(size: 12, weight: .semibold)).foregroundColor(.textSecondary)
                            HStack(spacing: 8) {
                                ForEach(BillingCycle.allCases, id: \.self) { cycle in
                                    Button { billingCycle = cycle } label: {
                                        Text(cycle.rawValue)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(billingCycle == cycle ? .white : .textSecondary)
                                            .padding(.horizontal, 14).padding(.vertical, 8)
                                            .background(billingCycle == cycle ? LinearGradient.brand : LinearGradient(colors: [Color.appSurface], startPoint: .leading, endPoint: .trailing))
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }
                    .padding(20).cardStyle()

                    if !isEditing {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Quick Add").font(.system(size: 14, weight: .semibold)).foregroundColor(.textSecondary)
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(presets, id: \.name) { p in
                                    Button {
                                        name = p.name; amountText = String(format: "%.2f", p.amount)
                                        category = p.category; emoji = p.emoji
                                    } label: {
                                        HStack(spacing: 8) {
                                            Text(p.emoji).font(.system(size: 18))
                                            VStack(alignment: .leading, spacing: 1) {
                                                Text(p.name).font(.system(size: 13, weight: .semibold)).foregroundColor(.textPrimary).lineLimit(1)
                                                Text("~$\(String(format: "%.0f", p.amount))/mo").font(.system(size: 10)).foregroundColor(.textSecondary)
                                            }
                                            Spacer()
                                        }
                                        .padding(.horizontal, 12).padding(.vertical, 10)
                                        .background(Color.appSurface).clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20).padding(.bottom, 40)
            }
            .navigationTitle(isEditing ? "Edit Fixed Cost" : "Add Fixed Cost")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(.brandOrange)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        guard !name.isEmpty, let amount = Double(amountText), amount > 0 else { return }
                        onSave(FixedCost(id: existingCost?.id ?? UUID(), name: name, amount: amount, category: category, emoji: emoji, billingCycle: billingCycle))
                        dismiss()
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(name.isEmpty || (Double(amountText) ?? 0) <= 0 ? .textSecondary : .brandOrange)
                    .disabled(name.isEmpty || (Double(amountText) ?? 0) <= 0)
                }
            }
            .onAppear {
                if let e = existingCost {
                    name = e.name; amountText = String(format: "%.2f", e.amount)
                    category = e.category; emoji = e.emoji; billingCycle = e.billingCycle
                } else { amountFocused = true }
            }
        }
    }
}

// MARK: - Add / Edit Subscription Sheet

struct AddSubscriptionSheet: View {
    let existing: FixedCost?
    let onSave: (FixedCost) -> Void

    @Environment(\.dismiss) var dismiss
    @State private var name: String = ""
    @State private var amountText: String = ""
    @State private var emoji: String = "📺"
    @State private var billingCycle: BillingCycle = .monthly
    @FocusState private var amountFocused: Bool

    private var isEditing: Bool { existing != nil }
    private let accentColor = Color(hex: "9B59B6")

    private struct SubPreset: Identifiable {
        let id = UUID()
        let name: String; let emoji: String; let amount: Double; let cycle: BillingCycle
        let groupLabel: String
    }

    private let presets: [SubPreset] = [
        // Streaming
        SubPreset(name: "Netflix",          emoji: "📺", amount: 15.99, cycle: .monthly,  groupLabel: "Streaming"),
        SubPreset(name: "Disney+",          emoji: "🏰", amount: 7.99,  cycle: .monthly,  groupLabel: "Streaming"),
        SubPreset(name: "Hulu",             emoji: "🎬", amount: 7.99,  cycle: .monthly,  groupLabel: "Streaming"),
        SubPreset(name: "HBO Max",          emoji: "🎭", amount: 15.99, cycle: .monthly,  groupLabel: "Streaming"),
        SubPreset(name: "Apple TV+",        emoji: "🍎", amount: 9.99,  cycle: .monthly,  groupLabel: "Streaming"),
        SubPreset(name: "YouTube Premium",  emoji: "▶️", amount: 13.99, cycle: .monthly,  groupLabel: "Streaming"),
        // Music
        SubPreset(name: "Spotify",          emoji: "🎵", amount: 10.99, cycle: .monthly,  groupLabel: "Music"),
        SubPreset(name: "Apple Music",      emoji: "🎶", amount: 10.99, cycle: .monthly,  groupLabel: "Music"),
        SubPreset(name: "Amazon Music",     emoji: "🎼", amount: 8.99,  cycle: .monthly,  groupLabel: "Music"),
        // Cloud & Software
        SubPreset(name: "iCloud+ 50GB",     emoji: "☁️", amount: 0.99,  cycle: .monthly,  groupLabel: "Cloud & Software"),
        SubPreset(name: "iCloud+ 200GB",    emoji: "☁️", amount: 2.99,  cycle: .monthly,  groupLabel: "Cloud & Software"),
        SubPreset(name: "Microsoft 365",    emoji: "💼", amount: 99.99, cycle: .annual,   groupLabel: "Cloud & Software"),
        SubPreset(name: "Adobe CC",         emoji: "🎨", amount: 54.99, cycle: .monthly,  groupLabel: "Cloud & Software"),
        SubPreset(name: "Amazon Prime",     emoji: "📦", amount: 139,   cycle: .annual,   groupLabel: "Cloud & Software"),
        // Health & Fitness
        SubPreset(name: "Gym",              emoji: "💪", amount: 40.00, cycle: .monthly,  groupLabel: "Health & Fitness"),
        SubPreset(name: "MyFitnessPal",     emoji: "🏃", amount: 19.99, cycle: .monthly,  groupLabel: "Health & Fitness"),
        SubPreset(name: "Calm",             emoji: "🧘", amount: 69.99, cycle: .annual,   groupLabel: "Health & Fitness"),
        SubPreset(name: "Headspace",        emoji: "🌿", amount: 99.99, cycle: .annual,   groupLabel: "Health & Fitness"),
        // Gaming
        SubPreset(name: "Xbox Game Pass",   emoji: "🎮", amount: 14.99, cycle: .monthly,  groupLabel: "Gaming"),
        SubPreset(name: "PlayStation Plus", emoji: "🕹️", amount: 59.99, cycle: .annual,   groupLabel: "Gaming"),
        SubPreset(name: "Nintendo Online",  emoji: "🎯", amount: 19.99, cycle: .annual,   groupLabel: "Gaming"),
        SubPreset(name: "Apple Arcade",     emoji: "👾", amount: 4.99,  cycle: .monthly,  groupLabel: "Gaming"),
    ]

    private var groups: [(label: String, items: [SubPreset])] {
        let labels = ["Streaming", "Music", "Cloud & Software", "Health & Fitness", "Gaming"]
        return labels.map { label in
            (label: label, items: presets.filter { $0.groupLabel == label })
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Amount input
                    VStack(spacing: 6) {
                        Text("Amount").font(.system(size: 13, weight: .semibold)).foregroundColor(.textSecondary)
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("$").font(.system(size: 32, weight: .bold)).foregroundColor(accentColor)
                            TextField("0.00", text: $amountText)
                                .font(.system(size: 44, weight: .bold)).foregroundColor(.textPrimary)
                                .keyboardType(.decimalPad).focused($amountFocused).multilineTextAlignment(.center)
                        }
                        // Billing cycle picker
                        HStack(spacing: 8) {
                            ForEach(BillingCycle.allCases, id: \.self) { cycle in
                                Button { billingCycle = cycle } label: {
                                    Text(cycle.rawValue)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(billingCycle == cycle ? .white : .textSecondary)
                                        .padding(.horizontal, 14).padding(.vertical, 8)
                                        .background(billingCycle == cycle ? accentColor : Color.appSurface)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        if billingCycle != .monthly, let amt = Double(amountText), amt > 0 {
                            let monthly = amt * billingCycle.perMonthMultiplier
                            Text("≈ $\(String(format: "%.2f", monthly)) / mo")
                                .font(.system(size: 12)).foregroundColor(accentColor)
                        }
                    }
                    .padding(.top, 8)

                    // Name + emoji
                    VStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Service Name").font(.system(size: 12, weight: .semibold)).foregroundColor(.textSecondary)
                            HStack(spacing: 10) {
                                Text(emoji).font(.system(size: 22))
                                TextField("e.g. Netflix", text: $name)
                                    .font(.system(size: 16)).padding(14)
                                    .background(Color.appSurface).clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    .padding(20).cardStyle()

                    // Preset groups
                    if !isEditing {
                        VStack(alignment: .leading, spacing: 20) {
                            ForEach(groups, id: \.label) { group in
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(group.label)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.textSecondary)
                                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                        ForEach(group.items) { p in
                                            Button {
                                                name = p.name; amountText = String(format: p.cycle == .annual ? "%.2f" : "%.2f", p.amount)
                                                emoji = p.emoji; billingCycle = p.cycle
                                            } label: {
                                                HStack(spacing: 8) {
                                                    Text(p.emoji).font(.system(size: 18))
                                                    VStack(alignment: .leading, spacing: 2) {
                                                        Text(p.name)
                                                            .font(.system(size: 13, weight: .semibold))
                                                            .foregroundColor(.textPrimary).lineLimit(1)
                                                        let monthly = p.amount * p.cycle.perMonthMultiplier
                                                        Text("~$\(String(format: "%.2f", monthly))/mo")
                                                            .font(.system(size: 10)).foregroundColor(.textSecondary)
                                                    }
                                                    Spacer()
                                                }
                                                .padding(.horizontal, 12).padding(.vertical, 10)
                                                .background(name == p.name ? accentColor.opacity(0.10) : Color.appSurface)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(name == p.name ? accentColor : Color.clear, lineWidth: 1.5))
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    PrimaryButton(title: isEditing ? "Save Changes" : "Add Subscription") {
                        guard !name.isEmpty, let amount = Double(amountText), amount > 0 else { return }
                        onSave(FixedCost(id: existing?.id ?? UUID(), name: name, amount: amount, category: .subscriptions, emoji: emoji, billingCycle: billingCycle))
                        dismiss()
                    }
                    .padding(.horizontal, 4)
                    .disabled(name.isEmpty || (Double(amountText) ?? 0) <= 0)
                }
                .padding(.horizontal, 20).padding(.bottom, 40)
            }
            .navigationTitle(isEditing ? "Edit Subscription" : "Add Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(accentColor)
                }
            }
            .onAppear {
                if let e = existing {
                    name = e.name; amountText = String(format: "%.2f", e.amount)
                    emoji = e.emoji; billingCycle = e.billingCycle
                } else { amountFocused = true }
            }
        }
    }
}
