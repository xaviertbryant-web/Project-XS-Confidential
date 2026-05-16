import SwiftUI

struct GoalsView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var vm = GoalsViewModel()
    @State private var appeared = false

    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var activeGoals: [Goal] { appViewModel.goals.filter { !$0.isCompleted } }
    var completedGoals: [Goal] { appViewModel.goals.filter { $0.isCompleted } }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appSurface.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        headerSection
                        summaryBanner
                        activeGoalsSection
                        if !completedGoals.isEmpty { completedGoalsSection }
                    }
                    .padding(.horizontal, AppTheme.horizontalPadding)
                    .padding(.top, 16)
                    .padding(.bottom, 100)
                }
            }
            .sheet(isPresented: $vm.showingAddGoal) {
                AddGoalSheet(vm: vm) { goal in
                    appViewModel.addGoal(goal)
                    vm.showingAddGoal = false
                }
            }
        }
    }

    var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Your Goals")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.textPrimary)
                Text("\(activeGoals.count) active · \(completedGoals.count) completed")
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
            }
            Spacer()
            Button {
                vm.showingAddGoal = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text("New Goal")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(LinearGradient.brand)
                .clipShape(Capsule())
            }
        }
    }

    var summaryBanner: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Total Saved")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.8))
                Text("$\(String(format: "%.0f", appViewModel.goals.reduce(0) { $0 + $1.currentAmount }))")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("Target")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.8))
                Text("$\(String(format: "%.0f", appViewModel.goals.reduce(0) { $0 + $1.targetAmount }))")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .padding(20)
        .background(LinearGradient.brand)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
        .shadow(color: .brandOrange.opacity(0.3), radius: 16, x: 0, y: 6)
    }

    var activeGoalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("In Progress")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.textPrimary)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(activeGoals) { goal in
                    GoalCardView(goal: goal) {
                        vm.selectedGoal = goal
                        vm.showingGoalDetail = true
                    }
                }
            }
        }
        .sheet(isPresented: $vm.showingGoalDetail) {
            if let goal = vm.selectedGoal {
                GoalDetailSheet(goal: goal)
            }
        }
    }

    var completedGoalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Completed 🏆")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.textPrimary)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(completedGoals) { goal in
                    GoalCardView(goal: goal)
                }
            }
        }
    }
}

struct AddGoalSheet: View {
    @ObservedObject var vm: GoalsViewModel
    var onSave: (Goal) -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    emojiPickerSection
                    formSection
                }
                .padding(20)
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let goal = vm.buildGoal() { onSave(goal) }
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.brandOrange)
                    .disabled(vm.newGoalTitle.isEmpty || vm.newGoalTarget.isEmpty)
                }
            }
        }
    }

    var emojiPickerSection: some View {
        VStack(spacing: 12) {
            Text(vm.newGoalEmoji)
                .font(.system(size: 64))
            Text("Choose an emoji")
                .font(.system(size: 14))
                .foregroundColor(.textSecondary)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 8) {
                ForEach(vm.emojiOptions, id: \.self) { emoji in
                    Button { vm.newGoalEmoji = emoji } label: {
                        Text(emoji)
                            .font(.system(size: 28))
                            .frame(width: 48, height: 48)
                            .background(vm.newGoalEmoji == emoji ? Color.brandOrange.opacity(0.15) : Color.appSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
        .padding(20)
        .cardStyle()
    }

    var formSection: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Goal Name").font(.system(size: 12, weight: .semibold)).foregroundColor(.textSecondary)
                TextField("e.g. Japan Trip", text: $vm.newGoalTitle)
                    .textFieldStyle(AppTextFieldStyle())
            }
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Target ($)").font(.system(size: 12, weight: .semibold)).foregroundColor(.textSecondary)
                    TextField("3000", text: $vm.newGoalTarget)
                        .textFieldStyle(AppTextFieldStyle())
                        .keyboardType(.decimalPad)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Monthly ($)").font(.system(size: 12, weight: .semibold)).foregroundColor(.textSecondary)
                    TextField("300", text: $vm.newGoalMonthly)
                        .textFieldStyle(AppTextFieldStyle())
                        .keyboardType(.decimalPad)
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Category").font(.system(size: 12, weight: .semibold)).foregroundColor(.textSecondary)
                Picker("Category", selection: $vm.newGoalCategory) {
                    ForEach(GoalCategory.allCases, id: \.self) { cat in
                        Text(cat.rawValue).tag(cat)
                    }
                }
                .pickerStyle(.menu)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.appSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(20)
        .cardStyle()
    }
}

struct AppTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<_Label>) -> some View {
        configuration
            .padding(14)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .font(.system(size: 15))
    }
}

struct GoalDetailSheet: View {
    let goal: Goal
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var addAmount: String = ""
    @State private var showingAddFunds = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        Text(goal.emoji).font(.system(size: 64))
                        Text(goal.title).font(.system(size: 24, weight: .bold)).foregroundColor(.textPrimary)
                        CircularProgressView(progress: goal.progress, size: 140, lineWidth: 14)
                    }
                    .padding(.top, 20)

                    HStack(spacing: 16) {
                        statBox(label: "Saved", value: "$\(String(format: "%.0f", goal.currentAmount))")
                        statBox(label: "Remaining", value: "$\(String(format: "%.0f", goal.remaining))")
                        statBox(label: "ETA", value: "\(goal.monthsToGoal) mo")
                    }
                    .padding(.horizontal, 20)

                    if !goal.isCompleted {
                        PrimaryButton(title: "Add Funds") {
                            showingAddFunds = true
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.brandOrange)
                }
            }
            .alert("Add Funds", isPresented: $showingAddFunds) {
                TextField("Amount", text: $addAmount).keyboardType(.decimalPad)
                Button("Add") {
                    if let amount = Double(addAmount) {
                        appViewModel.updateGoalAmount(goal, newAmount: goal.currentAmount + amount)
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    func statBox(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.system(size: 18, weight: .bold)).foregroundColor(.textPrimary)
            Text(label).font(.system(size: 12)).foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .cardStyle()
    }
}
