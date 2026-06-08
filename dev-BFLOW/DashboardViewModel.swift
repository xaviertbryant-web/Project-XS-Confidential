import SwiftUI

class DashboardViewModel: ObservableObject {
    @Published var greeting: String = ""
    @Published var showingNotificationBanner: Bool = false
    @Published var latestNotificationText: String = ""
    @Published var latestTransaction: Transaction? = nil

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

    func showNotification(for transaction: Transaction) {
        latestTransaction = transaction
        latestNotificationText = "\(transaction.title) — \(transaction.formattedAmount)"
        withAnimation { showingNotificationBanner = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation { self.showingNotificationBanner = false }
        }
    }
}
