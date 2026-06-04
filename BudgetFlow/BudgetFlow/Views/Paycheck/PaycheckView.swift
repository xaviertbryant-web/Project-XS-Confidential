import SwiftUI

struct PaycheckView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var notificationService: NotificationService
    @StateObject private var vm = PaycheckViewModel()
    @State private var showRulePicker = false
    @State private var showingAddFixedCost = false
    @State private var editingFixedCost: FixedCost? = nil
    @FocusState private var paycheckFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appSurface.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        headerSection
                        paycheckInputSection
                        fixedCostsSection
                        rulePickerSection
                        allocationSection
                        budgetBreakdownSection
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
            // Seed local VM from stored budget so they stay in sync
            vm.paycheckInput = String(format: "%.0f", appViewModel.paycheckBudget.paycheckAmount)
            vm.needsSlider = appViewModel.paycheckBudget.needsPercentage
            vm.wantsSlider = appViewModel.paycheckBudget.wantsPercentage
            vm.savingsSlider = appViewModel.paycheckBudget.savingsPercentage
            vm.selectedFrequency = appViewModel.paycheckBudget.frequency
        }
        // Push every slider/input change back to AppViewModel so home card stays live
        .onChange(of: vm.needsSlider)    { _, _ in syncToApp() }
        .onChange(of: vm.wantsSlider)    { _, _ in syncToApp() }
        .onChange(of: vm.savingsSlider)  { _, _ in syncToApp() }
        .onChange(of: vm.paycheckInput)  { _, _ in syncToApp() }
        .onChange(of: vm.selectedFrequency) { _, _ in syncToApp() }
        .sheet(isPresented: $showingAddFixedCost) {
            AddFixedCostSheet(existingCost: nil) { cost in
                appViewModel.paycheckBudget.fixedCosts.append(cost)
            }
        }
        .sheet(item: $editingFixedCost) { cost in
            AddFixedCostSheet(existingCost: cost) { updated in
                if let idx = appViewModel.paycheckBudget.fixedCosts.firstIndex(where: { $0.id == updated.id }) {
                    appViewModel.paycheckBudget.fixedCosts[idx] = updated
                }
            }
        }
    }

    private func syncToApp() {
        appViewModel.paycheckBudget.paycheckAmount  = vm.paycheck
        appViewModel.paycheckBudget.frequency       = vm.selectedFrequency
        appViewModel.paycheckBudget.needsPercentage = vm.needsSlider
        appViewModel.paycheckBudget.wantsPercentage = vm.wantsSlider
        appViewModel.paycheckBudget.savingsPercentage = vm.savingsSlider
    }

    // MARK: - Fixed costs

    var fixedCostsSection: some View {
        VStack(alignment: .leading, spacing: 16) {

            // Header row
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Fixed Monthly Costs")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.textPrimary)
                    Text("Recurring bills deducted before budget splits")
                        .font(.system(size: 11))
                        .foregroundColor(.textSecondary)
                }
                Spacer()
                Button { showingAddFixedCost = true } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                        Text("Add")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(LinearGradient.brand)
                    .clipShape(Capsule())
                }
            }

            // Committed vs income bar
            let budget = appViewModel.paycheckBudget
            let fraction = budget.fixedCostsFraction
            VStack(spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.successGreen.opacity(0.15))
                            .frame(height: 10)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                fraction > 0.75
                                    ? LinearGradient(colors: [.brandOrange, .brandRed], startPoint: .leading, endPoint: .trailing)
                                    : LinearGradient(colors: [Color(hex: "4A90E2")], startPoint: .leading, endPoint: .trailing)
                            )
                            .frame(width: geo.size.width * CGFloat(fraction), height: 10)
                            .animation(.spring(response: 0.7, dampingFraction: 0.8), value: fraction)
                    }
                }
                .frame(height: 10)

                HStack {
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: "4A90E2"))
                            .frame(width: 10, height: 4)
                        Text("$\(String(format: "%.2f", budget.totalFixedCosts)) committed")
                            .font(.system(size: 11))
                            .foregroundColor(.textSecondary)
                    }
                    Spacer()
                    Text("$\(String(format: "%.2f", budget.discretionaryIncome)) discretionary")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.successGreen)
                }
            }

            // Cost rows
            if appViewModel.paycheckBudget.fixedCosts.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.dashed")
                        .font(.system(size: 28))
                        .foregroundColor(.textSecondary.opacity(0.5))
                    Text("No fixed costs yet. Tap Add to track rent, bills and subscriptions.")
                        .font(.system(size: 13))
                        .foregroundColor(.textSecondary)
                }
                .padding(.vertical, 8)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(appViewModel.paycheckBudget.fixedCosts.enumerated()), id: \.element.id) { index, cost in
                        fixedCostRow(cost: cost)
                        if index < appViewModel.paycheckBudget.fixedCosts.count - 1 {
                            Divider().padding(.leading, 56)
                        }
                    }
                }
                .background(Color.appSurface)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(20)
        .cardStyle()
    }

    func fixedCostRow(cost: FixedCost) -> some View {
        HStack(spacing: 14) {
            // Emoji + category colour ring
            ZStack {
                Circle()
                    .fill(Color(hex: cost.category.color).opacity(0.12))
                    .frame(width: 42, height: 42)
                Text(cost.emoji)
                    .font(.system(size: 20))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(cost.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textPrimary)
                Text(cost.category.rawValue)
                    .font(.system(size: 11))
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            Text("$\(String(format: "%.2f", cost.amount))")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.textPrimary)

            // Edit button
            Button { editingFixedCost = cost } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 13))
                    .foregroundColor(.textSecondary)
                    .frame(width: 30, height: 30)
            }

            // Delete button
            Button {
                withAnimation {
                    appViewModel.paycheckBudget.fixedCosts.removeAll { $0.id == cost.id }
                }
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 13))
                    .foregroundColor(.brandRed.opacity(0.7))
                    .frame(width: 30, height: 30)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Paycheck Planner")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.textPrimary)
            Text("Split your paycheck the smart way")
                .font(.system(size: 14))
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var paycheckInputSection: some View {
        VStack(spacing: 16) {
            HStack(alignment: .bottom, spacing: 8) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Paycheck Amount")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.textSecondary)
                    HStack {
                        Text("$")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.brandOrange)
                        TextField("0", text: $vm.paycheckInput)
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.textPrimary)
                            .keyboardType(.decimalPad)
                            .focused($paycheckFocused)
                    }
                }
                Spacer()
                Picker("", selection: $vm.selectedFrequency) {
                    ForEach(PayFrequency.allCases, id: \.self) { freq in
                        Text(freq.rawValue).tag(freq)
                    }
                }
                .pickerStyle(.menu)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.appSurface)
                .clipShape(Capsule())
            }
            .padding(20)
            .cardStyle()
        }
    }

    var rulePickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Budget Rule")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.textSecondary)
            HStack(spacing: 10) {
                ForEach(BudgetRule.allCases, id: \.self) { rule in
                    Button { vm.applyRule(rule) } label: {
                        VStack(spacing: 4) {
                            Text(rule.rawValue)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(vm.selectedRule == rule ? .white : .textPrimary)
                            Text(rule.description)
                                .font(.system(size: 10))
                                .foregroundColor(vm.selectedRule == rule ? .white.opacity(0.8) : .textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(vm.selectedRule == rule ? LinearGradient.brand : LinearGradient(colors: [Color.appSurface], startPoint: .leading, endPoint: .trailing))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
        }
    }

    var allocationSection: some View {
        VStack(spacing: 16) {
            allocationRow(
                label: "Needs",
                sublabel: "Rent, groceries, utilities",
                percentage: $vm.needsSlider,
                amount: vm.needsAmount,
                color: .brandOrange,
                emoji: "🏠"
            )
            allocationRow(
                label: "Wants",
                sublabel: "Dining, entertainment, fun",
                percentage: $vm.wantsSlider,
                amount: vm.wantsAmount,
                color: .brandRed,
                emoji: "🎉"
            )
            allocationRow(
                label: "Savings",
                sublabel: "Goals, investments, emergency",
                percentage: $vm.savingsSlider,
                amount: vm.savingsAmount,
                color: .successGreen,
                emoji: "💰"
            )
        }
        .padding(20)
        .cardStyle()
    }

    func allocationRow(label: String, sublabel: String, percentage: Binding<Double>, amount: Double, color: Color, emoji: String) -> some View {
        VStack(spacing: 10) {
            HStack {
                Text(emoji).font(.system(size: 20))
                VStack(alignment: .leading, spacing: 2) {
                    Text(label).font(.system(size: 15, weight: .semibold)).foregroundColor(.textPrimary)
                    Text(sublabel).font(.system(size: 11)).foregroundColor(.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("$\(String(format: "%.0f", amount))")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(color)
                    Text("\(Int(percentage.wrappedValue * 100))%")
                        .font(.system(size: 12))
                        .foregroundColor(.textSecondary)
                }
            }
            Slider(value: percentage, in: 0.05...0.90, step: 0.01)
                .tint(color)
                .onChange(of: percentage.wrappedValue) { _, _ in
                    // Normalize percentages
                    let total = vm.needsSlider + vm.wantsSlider + vm.savingsSlider
                    if total > 1.0 {
                        let excess = total - 1.0
                        if label == "Needs" { vm.wantsSlider = max(0.05, vm.wantsSlider - excess) }
                        else if label == "Wants" { vm.savingsSlider = max(0.05, vm.savingsSlider - excess) }
                        else { vm.wantsSlider = max(0.05, vm.wantsSlider - excess) }
                    }
                }
        }
    }

    var budgetBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Monthly Budget")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.textPrimary)

            let monthlyNeeds = vm.needsAmount * (vm.selectedFrequency == .biweekly ? 2.167 : 1)
            let monthlyWants = vm.wantsAmount * (vm.selectedFrequency == .biweekly ? 2.167 : 1)
            let monthlySavings = vm.savingsAmount * (vm.selectedFrequency == .biweekly ? 2.167 : 1)

            SpendingBarView(label: "Needs", spent: monthlyNeeds * 0.72, budget: monthlyNeeds, color: .brandOrange)
            SpendingBarView(label: "Wants", spent: monthlyWants * 0.58, budget: monthlyWants, color: .brandRed)
            SpendingBarView(label: "Savings", spent: monthlySavings * 0.90, budget: monthlySavings, color: .successGreen)
        }
        .padding(20)
        .cardStyle()
    }

    var bankNotificationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bank Notifications")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.textPrimary)
                    Text("Let BudgetFlow read your bank alerts to auto-update your budget")
                        .font(.system(size: 12))
                        .foregroundColor(.textSecondary)
                }
                Spacer()
                Toggle("", isOn: .constant(notificationService.permissionGranted))
                    .tint(.brandOrange)
                    .labelsHidden()
            }

            if !notificationService.permissionGranted {
                Button {
                    Task { await notificationService.requestPermission() }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "bell.badge.fill").foregroundColor(.brandOrange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Enable notifications").font(.system(size: 14, weight: .semibold)).foregroundColor(.textPrimary)
                            Text("We'll detect spend from bank texts & emails").font(.system(size: 11)).foregroundColor(.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundColor(.textSecondary).font(.system(size: 12))
                    }
                    .padding(16)
                    .background(Color.brandOrange.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.successGreen)
                    Text("Notifications active – auto-tracking spend").font(.system(size: 13)).foregroundColor(.successGreen)
                }
            }
        }
        .padding(20)
        .cardStyle()
    }
}

// MARK: - Add / Edit Fixed Cost Sheet

struct AddFixedCostSheet: View {
    let existingCost: FixedCost?
    let onSave: (FixedCost) -> Void

    @Environment(\.dismiss) var dismiss
    @State private var name: String = ""
    @State private var amountText: String = ""
    @State private var category: FixedCostCategory = .other
    @State private var emoji: String = "📌"
    @FocusState private var amountFocused: Bool

    private var isEditing: Bool { existingCost != nil }

    // Quick-add presets
    private let presets: [(name: String, amount: Double, category: FixedCostCategory, emoji: String)] = [
        ("Rent",          1200, .housing,       "🏠"),
        ("Mortgage",      1500, .housing,       "🏡"),
        ("Electric",       90,  .utilities,     "⚡"),
        ("Gas",            40,  .utilities,     "🔥"),
        ("Internet",       60,  .utilities,     "📡"),
        ("Water",          35,  .utilities,     "💧"),
        ("Car Insurance", 120,  .insurance,     "🛡️"),
        ("Health Ins.",   180,  .insurance,     "🏥"),
        ("Phone Plan",     45,  .phone,         "📱"),
        ("Netflix",        16,  .subscriptions, "📺"),
        ("Spotify",        11,  .subscriptions, "🎵"),
        ("Gym",            40,  .subscriptions, "💪"),
        ("Car Loan",      320,  .transport,     "🚗"),
        ("Transit Pass",   90,  .transport,     "🚇"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {

                    // Amount input
                    VStack(spacing: 8) {
                        Text("Monthly Amount")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.textSecondary)
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("$")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.brandOrange)
                            TextField("0.00", text: $amountText)
                                .font(.system(size: 44, weight: .bold))
                                .foregroundColor(.textPrimary)
                                .keyboardType(.decimalPad)
                                .focused($amountFocused)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.top, 8)

                    // Name + category
                    VStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Name").font(.system(size: 12, weight: .semibold)).foregroundColor(.textSecondary)
                            HStack(spacing: 10) {
                                Text(emoji).font(.system(size: 22))
                                TextField("e.g. Rent", text: $name)
                                    .font(.system(size: 16))
                                    .padding(14)
                                    .background(Color.appSurface)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Category").font(.system(size: 12, weight: .semibold)).foregroundColor(.textSecondary)
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                                ForEach(FixedCostCategory.allCases, id: \.self) { cat in
                                    Button {
                                        category = cat
                                        if emoji == FixedCostCategory.other.defaultEmoji || emoji == "📌" {
                                            emoji = cat.defaultEmoji
                                        }
                                    } label: {
                                        VStack(spacing: 4) {
                                            Text(cat.defaultEmoji).font(.system(size: 20))
                                            Text(cat.rawValue)
                                                .font(.system(size: 9, weight: .medium))
                                                .foregroundColor(category == cat ? Color(hex: cat.color) : .textSecondary)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.8)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(category == cat ? Color(hex: cat.color).opacity(0.12) : Color.appSurface)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(category == cat ? Color(hex: cat.color) : Color.clear, lineWidth: 1.5)
                                        )
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                    .cardStyle()

                    // Quick-add presets (only shown when not editing)
                    if !isEditing {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Quick Add")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.textSecondary)
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(presets, id: \.name) { preset in
                                    Button {
                                        name = preset.name
                                        amountText = String(format: "%.2f", preset.amount)
                                        category = preset.category
                                        emoji = preset.emoji
                                    } label: {
                                        HStack(spacing: 8) {
                                            Text(preset.emoji).font(.system(size: 18))
                                            VStack(alignment: .leading, spacing: 1) {
                                                Text(preset.name)
                                                    .font(.system(size: 13, weight: .semibold))
                                                    .foregroundColor(.textPrimary)
                                                    .lineLimit(1)
                                                Text("~$\(String(format: "%.0f", preset.amount))/mo")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.textSecondary)
                                            }
                                            Spacer()
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                        .background(Color.appSurface)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
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
                        let cost = FixedCost(
                            id: existingCost?.id ?? UUID(),
                            name: name,
                            amount: amount,
                            category: category,
                            emoji: emoji
                        )
                        onSave(cost)
                        dismiss()
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(name.isEmpty || (Double(amountText) ?? 0) <= 0 ? .textSecondary : .brandOrange)
                    .disabled(name.isEmpty || (Double(amountText) ?? 0) <= 0)
                }
            }
            .onAppear {
                if let existing = existingCost {
                    name = existing.name
                    amountText = String(format: "%.2f", existing.amount)
                    category = existing.category
                    emoji = existing.emoji
                } else {
                    amountFocused = true
                }
            }
        }
    }
}
