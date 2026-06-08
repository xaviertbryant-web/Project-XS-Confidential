import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tag(0)
                PaycheckView()
                    .tag(1)
                GoalsView()
                    .tag(2)
                InsightsView()
                    .tag(3)
                SettingsView()
                    .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $appViewModel.showingGoalCompletion) {
            if let goal = appViewModel.completedGoal {
                GoalCompletionView(goal: goal)
            }
        }
        .overlay(alignment: .top) {
            if appViewModel.showApplePayLock {
                ApplePayLockOverlay()
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(100)
            }
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int

    let items: [(icon: String, label: String)] = [
        ("house.fill", "Home"),
        ("dollarsign.circle.fill", "Budget"),
        ("target", "Goals"),
        ("chart.bar.fill", "Insights"),
        ("gearshape.fill", "Settings"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<items.count, id: \.self) { index in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = index
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: items[index].icon)
                            .font(.system(size: selectedTab == index ? 22 : 20, weight: .semibold))
                            .foregroundStyle(selectedTab == index ? LinearGradient.brand : LinearGradient(colors: [.textSecondary], startPoint: .top, endPoint: .bottom))
                            .scaleEffect(selectedTab == index ? 1.1 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedTab)

                        Text(items[index].label)
                            .font(.system(size: 10, weight: selectedTab == index ? .semibold : .regular))
                            .foregroundColor(selectedTab == index ? .brandOrange : .textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 4)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(.white)
                .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: -4)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}
