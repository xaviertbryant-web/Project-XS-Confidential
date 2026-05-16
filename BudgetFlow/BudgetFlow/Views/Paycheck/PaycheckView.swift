import SwiftUI

struct PaycheckView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var notificationService: NotificationService
    @StateObject private var vm = PaycheckViewModel()
    @State private var showRulePicker = false
    @FocusState private var paycheckFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appSurface.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        headerSection
                        paycheckInputSection
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
