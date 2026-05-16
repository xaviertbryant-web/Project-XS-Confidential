import SwiftUI

class DashboardViewModel: ObservableObject {
    @Published var greeting: String = ""
    @Published var showingNotificationBanner: Bool = false
    @Published var latestNotificationText: String = ""

    init() {
        updateGreeting()
    }

    func updateGreeting() {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: greeting = "Good morning"
        case 12..<17: greeting = "Good afternoon"
        default: greeting = "Good evening"
        }
    }

    func simulateBankNotification(transaction: String, amount: Double) {
        latestNotificationText = "\(transaction) — $\(String(format: "%.2f", amount))"
        withAnimation { showingNotificationBanner = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation { self.showingNotificationBanner = false }
        }
    }
}
