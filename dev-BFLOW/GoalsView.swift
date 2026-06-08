import SwiftUI

struct GoalsView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var vm = GoalsViewModel()
    @State private var appeared = false
    @State private var editingGoal: Goal? = nil

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
            .sheet(item: $editingGoal) { goal in
                EditGoalSheet(goal: goal) { updated in
                    appViewModel.updateGoalFull(updated)
                } onDelete: {
                    appViewModel.deleteGoal(goal)
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
                    GoalCardView(
                        goal: goal,
                        onTap: { vm.selectedGoal = goal; vm.showingGoalDetail = true },
                        onEdit: { editingGoal = goal },
                        onDelete: { appViewModel.deleteGoal(goal) }
                    )
                }
            }
        }
        .sheet(isPresented: $vm.showingGoalDetail) {
            if let goal = vm.selectedGoal {
                GoalDetailSheet(
                    goal: goal,
                    onEdit: { vm.showingGoalDetail = false; DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { editingGoal = goal } },
                    onDelete: { appViewModel.deleteGoal(goal); vm.showingGoalDetail = false }
                )
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
                    GoalCardView(
                        goal: goal,
                        onEdit: { editingGoal = goal },
                        onDelete: { appViewModel.deleteGoal(goal) }
                    )
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
    let onEdit: () -> Void
    let onDelete: () -> Void
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var addAmount: String = ""
    @State private var showingAddFunds = false
    @State private var showingDeleteConfirm = false

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
                        statBox(label: "Saved",     value: "$\(String(format: "%.0f", goal.currentAmount))")
                        statBox(label: "Remaining", value: "$\(String(format: "%.0f", goal.remaining))")
                        statBox(label: "ETA",       value: goal.isCompleted ? "Done" : "\(goal.monthsToGoal) mo")
                    }
                    .padding(.horizontal, 20)

                    if !goal.isCompleted {
                        VStack(spacing: 12) {
                            PrimaryButton(title: "Add Funds") { showingAddFunds = true }
                            Button {
                                onEdit()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "pencil")
                                    Text("Edit Goal")
                                }
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.brandOrange)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.brandOrange.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    Button(role: .destructive) {
                        showingDeleteConfirm = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "trash")
                            Text("Delete Goal")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.brandRed)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color.brandRed.opacity(0.07))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }.foregroundColor(.brandOrange)
                }
                if !goal.isCompleted {
                    ToolbarItem(placement: .confirmationAction) {
                        Button { onEdit() } label: {
                            Image(systemName: "pencil")
                        }
                        .foregroundColor(.brandOrange)
                    }
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
            .confirmationDialog("Delete \"\(goal.title)\"?", isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
                Button("Delete Goal", role: .destructive) { onDelete() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This cannot be undone.")
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

// MARK: - Edit Goal Sheet

struct EditGoalSheet: View {
    let goal: Goal
    let onSave: (Goal) -> Void
    let onDelete: () -> Void

    @Environment(\.dismiss) var dismiss
    @State private var title: String
    @State private var targetText: String
    @State private var currentText: String
    @State private var monthlyText: String
    @State private var targetDate: Date
    @State private var emoji: String
    @State private var category: GoalCategory
    @State private var showingDeleteConfirm = false

    private let emojiOptions = ["⭐", "✈️", "🏠", "🚗", "💻", "📱", "🎓", "🛡️", "💰", "🎯", "🌴", "💎",
                                 "🏋️", "🎨", "🎵", "🍕", "☕", "🌍", "🏖️", "🎮", "🐾", "💍", "🎂", "🏆"]

    init(goal: Goal, onSave: @escaping (Goal) -> Void, onDelete: @escaping () -> Void) {
        self.goal = goal
        self.onSave = onSave
        self.onDelete = onDelete
        _title = State(initialValue: goal.title)
        _targetText = State(initialValue: String(format: "%.0f", goal.targetAmount))
        _currentText = State(initialValue: String(format: "%.0f", goal.currentAmount))
        _monthlyText = State(initialValue: String(format: "%.0f", goal.monthlyContribution))
        _targetDate = State(initialValue: goal.targetDate)
        _emoji = State(initialValue: goal.emoji)
        _category = State(initialValue: goal.category)
    }

    private var canSave: Bool {
        !title.isEmpty && (Double(targetText) ?? 0) > 0 && (Double(monthlyText) ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Emoji picker
                    VStack(spacing: 12) {
                        Text(emoji).font(.system(size: 64))
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 8) {
                            ForEach(emojiOptions, id: \.self) { e in
                                Button { emoji = e } label: {
                                    Text(e).font(.system(size: 26))
                                        .frame(width: 46, height: 46)
                                        .background(emoji == e ? Color.brandOrange.opacity(0.15) : Color.appSurface)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(emoji == e ? Color.brandOrange : Color.clear, lineWidth: 1.5))
                                }
                            }
                        }
                    }
                    .padding(20).cardStyle()

                    // Fields
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Goal Name").font(.system(size: 12, weight: .semibold)).foregroundColor(.textSecondary)
                            TextField("e.g. Japan Trip", text: $title).textFieldStyle(AppTextFieldStyle())
                        }

                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Target ($)").font(.system(size: 12, weight: .semibold)).foregroundColor(.textSecondary)
                                TextField("3000", text: $targetText)
                                    .textFieldStyle(AppTextFieldStyle()).keyboardType(.decimalPad)
                            }
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Saved so far ($)").font(.system(size: 12, weight: .semibold)).foregroundColor(.textSecondary)
                                TextField("0", text: $currentText)
                                    .textFieldStyle(AppTextFieldStyle()).keyboardType(.decimalPad)
                            }
                        }

                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Monthly ($)").font(.system(size: 12, weight: .semibold)).foregroundColor(.textSecondary)
                                TextField("300", text: $monthlyText)
                                    .textFieldStyle(AppTextFieldStyle()).keyboardType(.decimalPad)
                            }
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Target Date").font(.system(size: 12, weight: .semibold)).foregroundColor(.textSecondary)
                                DatePicker("", selection: $targetDate, displayedComponents: .date)
                                    .labelsHidden()
                                    .padding(10)
                                    .background(Color.appSurface)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Category").font(.system(size: 12, weight: .semibold)).foregroundColor(.textSecondary)
                            Picker("Category", selection: $category) {
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
                    .padding(20).cardStyle()

                    // Delete
                    Button(role: .destructive) {
                        showingDeleteConfirm = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "trash")
                            Text("Delete Goal")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.brandRed)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.brandRed.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(.horizontal, 20).padding(.bottom, 40)
            }
            .navigationTitle("Edit Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(.brandOrange)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard canSave,
                              let target = Double(targetText),
                              let current = Double(currentText),
                              let monthly = Double(monthlyText) else { return }
                        var updated = goal
                        updated.title = title
                        updated.targetAmount = target
                        updated.currentAmount = min(current, target)
                        updated.monthlyContribution = monthly
                        updated.targetDate = targetDate
                        updated.emoji = emoji
                        updated.category = category
                        onSave(updated)
                        dismiss()
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(canSave ? .brandOrange : .textSecondary)
                    .disabled(!canSave)
                }
            }
            .confirmationDialog("Delete \"\(goal.title)\"?", isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
                Button("Delete Goal", role: .destructive) { onDelete(); dismiss() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This cannot be undone.")
            }
        }
    }
}
