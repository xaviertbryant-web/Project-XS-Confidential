import UserNotifications
import SwiftUI

class NotificationService: ObservableObject {
    @Published var permissionGranted: Bool = false
    @Published var parsedTransactions: [Transaction] = []

    func requestPermission() async {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run { self.permissionGranted = granted }
        } catch {
            print("Notification permission error: \(error)")
        }
    }

    func checkPermissionStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            self.permissionGranted = settings.authorizationStatus == .authorized
        }
    }

    // Parse bank notification text to extract transaction info
    func parseNotification(body: String) -> Transaction? {
        // Pattern: "You spent $XX.XX at Merchant on Card ****1234"
        let patterns: [(regex: String, isIncome: Bool)] = [
            ("(?i)(?:spent|payment of|charge of)\\s*\\$?([\\d,.]+)\\s*(?:at|to|for)?\\s*([\\w\\s]+)", false),
            ("(?i)(?:deposit|credit|received)\\s*\\$?([\\d,.]+)\\s*(?:from)?\\s*([\\w\\s]+)", true),
        ]

        for (pattern, isIncome) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: body, range: NSRange(body.startIndex..., in: body)) {
                let amountRange = Range(match.range(at: 1), in: body)
                let merchantRange = Range(match.range(at: 2), in: body)

                if let amountStr = amountRange.map({ String(body[$0]).replacingOccurrences(of: ",", with: "") }),
                   let amount = Double(amountStr),
                   let merchant = merchantRange.map({ String(body[$0]).trimmingCharacters(in: .whitespaces) }) {
                    return Transaction(
                        id: UUID(),
                        title: merchant,
                        amount: amount,
                        category: categorize(merchant: merchant),
                        date: Date(),
                        isIncome: isIncome,
                        merchant: merchant,
                        fromNotification: true
                    )
                }
            }
        }
        return nil
    }

    private func categorize(merchant: String) -> TransactionCategory {
        let lower = merchant.lowercased()
        if ["starbucks", "mcdonald", "chipotle", "subway", "doordash", "uber eats", "grubhub", "whole foods", "trader joe"].contains(where: { lower.contains($0) }) { return .food }
        if ["uber", "lyft", "bp", "shell", "chevron", "transit", "metro"].contains(where: { lower.contains($0) }) { return .transport }
        if ["amazon", "zara", "h&m", "asos", "nike", "apple store"].contains(where: { lower.contains($0) }) { return .shopping }
        if ["netflix", "spotify", "hulu", "disney", "xbox", "steam"].contains(where: { lower.contains($0) }) { return .entertainment }
        if ["electric", "water", "internet", "at&t", "verizon", "comcast"].contains(where: { lower.contains($0) }) { return .bills }
        if ["cvs", "walgreens", "pharmacy", "hospital", "clinic"].contains(where: { lower.contains($0) }) { return .health }
        return .other
    }
}
