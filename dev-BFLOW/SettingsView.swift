import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var biometricService: BiometricService
    @EnvironmentObject var notificationService: NotificationService
    @State private var showingApplePaySetup = false
    @State private var showingPINSetup = false
    @State private var newName = ""
    @State private var editingName = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appSurface.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        profileSection
                        applePaySection
                        notificationsSection
                        bankConnectionSection
                        aboutSection
                    }
                    .padding(.horizontal, AppTheme.horizontalPadding)
                    .padding(.top, 16)
                    .padding(.bottom, 100)
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingPINSetup) {
            PINSetupSheet()
        }
    }

    var profileSection: some View {
        VStack(spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(LinearGradient.brand)
                        .frame(width: 64, height: 64)
                    Text(appViewModel.profile.avatarInitials)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 4) {
                    if editingName {
                        TextField("Your name", text: $newName)
                            .font(.system(size: 20, weight: .bold))
                            .onSubmit {
                                if !newName.isEmpty { appViewModel.profile.name = newName }
                                editingName = false
                            }
                    } else {
                        Text(appViewModel.profile.name)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.textPrimary)
                    }
                    Text("BudgetFlow Member")
                        .font(.system(size: 13))
                        .foregroundColor(.textSecondary)
                }
                Spacer()
                Button { editingName.toggle(); newName = appViewModel.profile.name } label: {
                    Image(systemName: editingName ? "checkmark" : "pencil")
                        .foregroundColor(.brandOrange)
                        .font(.system(size: 16))
                }
            }

            HStack(spacing: 0) {
                statItem(value: "$\(String(format: "%.0f", appViewModel.profile.totalBalance))", label: "Balance")
                Divider().frame(height: 40)
                statItem(value: "\(Int(appViewModel.profile.savingsRate * 100))%", label: "Save Rate")
                Divider().frame(height: 40)
                statItem(value: "\(appViewModel.goals.filter { $0.isCompleted }.count)", label: "Goals Done")
            }
        }
        .padding(20)
        .cardStyle()
    }

    func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.system(size: 16, weight: .bold)).foregroundColor(.textPrimary)
            Text(label).font(.system(size: 11)).foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    var applePaySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(icon: "wave.3.right.circle.fill", title: "Apple Pay Protection", color: .brandOrange)

            VStack(spacing: 1) {
                settingRow(
                    icon: "lock.shield.fill",
                    iconColor: .brandOrange,
                    title: "Payment Lock",
                    subtitle: "Require auth before every Apple Pay payment"
                ) {
                    Toggle("", isOn: $appViewModel.profile.applePayLockEnabled)
                        .tint(.brandOrange)
                        .labelsHidden()
                }

                if appViewModel.profile.applePayLockEnabled {
                    Divider().padding(.horizontal, 16)
                    settingRow(
                        icon: biometricService.biometricIconName,
                        iconColor: .brandOrange,
                        title: "Use \(biometricService.biometricName)",
                        subtitle: "Quick auth with biometrics"
                    ) {
                        Toggle("", isOn: $appViewModel.profile.useFaceIDForApplePay)
                            .tint(.brandOrange)
                            .labelsHidden()
                    }

                    Divider().padding(.horizontal, 16)
                    Button { showingPINSetup = true } label: {
                        settingRow(
                            icon: "number.circle.fill",
                            iconColor: .brandRed,
                            title: "Change PIN",
                            subtitle: "Set a 6-digit backup PIN"
                        ) {
                            Image(systemName: "chevron.right")
                                .foregroundColor(.textSecondary)
                                .font(.system(size: 12))
                        }
                    }
                    .buttonStyle(.plain)

                    Divider().padding(.horizontal, 16)
                    Button {
                        withAnimation { appViewModel.showApplePayLock = true }
                    } label: {
                        settingRow(
                            icon: "play.circle.fill",
                            iconColor: .successGreen,
                            title: "Test Lock Screen",
                            subtitle: "Preview how it looks before Apple Pay"
                        ) {
                            Image(systemName: "chevron.right")
                                .foregroundColor(.textSecondary)
                                .font(.system(size: 12))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            if appViewModel.profile.applePayLockEnabled {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill").foregroundColor(.brandOrange).font(.system(size: 14))
                    Text("A confirmation screen will appear before every Apple Pay payment. This prevents accidental or unauthorized purchases.")
                        .font(.system(size: 12))
                        .foregroundColor(.textSecondary)
                }
                .padding(14)
                .background(Color.brandOrange.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(icon: "bell.badge.fill", title: "Notifications", color: .brandRed)

            VStack(spacing: 1) {
                settingRow(icon: "bell.fill", iconColor: .brandRed, title: "Bank Alerts", subtitle: "Auto-detect transactions from notifications") {
                    Toggle("", isOn: .constant(notificationService.permissionGranted))
                        .tint(.brandOrange)
                        .labelsHidden()
                        .disabled(true)
                }
                Divider().padding(.horizontal, 16)
                settingRow(icon: "target", iconColor: .brandOrange, title: "Goal Milestones", subtitle: "Celebrate when you hit 25%, 50%, 75%") {
                    Toggle("", isOn: $appViewModel.profile.goalMilestonesEnabled).tint(.brandOrange).labelsHidden()
                }
                Divider().padding(.horizontal, 16)
                settingRow(icon: "exclamationmark.triangle.fill", iconColor: .warningYellow, title: "Budget Warnings", subtitle: "Alert when approaching category limit") {
                    Toggle("", isOn: $appViewModel.profile.budgetWarningsEnabled).tint(.brandOrange).labelsHidden()
                }
            }
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    var bankConnectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(icon: "building.columns.fill", title: "Bank Connection", color: Color(hex: "4A90E2"))

            VStack(spacing: 12) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(appViewModel.profile.bankConnected ? Color.successGreen.opacity(0.15) : Color.appSurface)
                            .frame(width: 44, height: 44)
                        Image(systemName: appViewModel.profile.bankConnected ? "checkmark.circle.fill" : "link.circle")
                            .foregroundColor(appViewModel.profile.bankConnected ? .successGreen : .textSecondary)
                            .font(.system(size: 24))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(appViewModel.profile.bankConnected ? "Bank Connected" : "Connect Your Bank")
                            .font(.system(size: 15, weight: .semibold)).foregroundColor(.textPrimary)
                        Text(appViewModel.profile.bankConnected ? "Auto-syncing transactions" : "Or use notification tracking instead")
                            .font(.system(size: 12)).foregroundColor(.textSecondary)
                    }
                    Spacer()
                }

                if !appViewModel.profile.bankConnected {
                    PrimaryButton(title: "Connect via Plaid (Demo)", action: {
                        appViewModel.profile.bankConnected = true
                    })
                    PrimaryButton(title: "Use Notification Tracking", style: .outlined, action: {
                        Task { await notificationService.requestPermission() }
                    })
                } else {
                    Button {
                        appViewModel.profile.bankConnected = false
                    } label: {
                        Text("Disconnect Bank")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.brandRed)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.brandRed.opacity(0.07))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding(20)
            .cardStyle()
        }
    }

    var aboutSection: some View {
        VStack(spacing: 1) {
            settingRow(icon: "star.fill", iconColor: .brandAmber, title: "Rate BudgetFlow", subtitle: nil) {
                Image(systemName: "chevron.right").foregroundColor(.textSecondary).font(.system(size: 12))
            }
            Divider().padding(.horizontal, 16)
            settingRow(icon: "shield.lefthalf.filled", iconColor: Color(hex: "4A90E2"), title: "Privacy Policy", subtitle: nil) {
                Image(systemName: "chevron.right").foregroundColor(.textSecondary).font(.system(size: 12))
            }
            Divider().padding(.horizontal, 16)
            settingRow(icon: "info.circle.fill", iconColor: .textSecondary, title: "Version 1.0.0", subtitle: "BudgetFlow for iOS") {
                EmptyView()
            }
        }
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    func sectionHeader(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).foregroundColor(color)
            Text(title).font(.system(size: 16, weight: .bold)).foregroundColor(.textPrimary)
        }
    }

    @ViewBuilder
    func settingRow<T: View>(icon: String, iconColor: Color, title: String, subtitle: String?, @ViewBuilder trailing: () -> T) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon).foregroundColor(iconColor).font(.system(size: 16))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 15, weight: .medium)).foregroundColor(.textPrimary)
                if let subtitle = subtitle {
                    Text(subtitle).font(.system(size: 11)).foregroundColor(.textSecondary)
                }
            }
            Spacer()
            trailing()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct PINSetupSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var pin = ""
    @State private var confirmPin = ""
    @State private var step = 0
    @State private var error = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                Image(systemName: "lock.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(LinearGradient.brand)

                VStack(spacing: 8) {
                    Text(step == 0 ? "Set your PIN" : "Confirm your PIN")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.textPrimary)
                    Text(step == 0 ? "Choose a 6-digit PIN for Apple Pay" : "Enter the same PIN again")
                        .font(.system(size: 14))
                        .foregroundColor(.textSecondary)
                    if !error.isEmpty {
                        Text(error).font(.system(size: 13)).foregroundColor(.brandRed)
                    }
                }

                PINDotsView(filledCount: step == 0 ? pin.count : confirmPin.count)

                NumberPadView(pin: step == 0 ? $pin : $confirmPin, maxDigits: 6) { enteredPIN in
                    if step == 0 {
                        step = 1
                    } else {
                        if enteredPIN == pin {
                            appViewModel.profile.applePayPIN = pin
                            dismiss()
                        } else {
                            error = "PINs don't match. Try again."
                            confirmPin = ""
                        }
                    }
                }
                Spacer()
            }
            .navigationTitle("Set PIN")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(.brandOrange)
                }
            }
        }
    }
}
