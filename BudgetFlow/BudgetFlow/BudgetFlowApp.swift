import SwiftUI

@main
struct BudgetFlowApp: App {
    @StateObject private var appViewModel = AppViewModel()
    @StateObject private var notificationService = NotificationService()
    @StateObject private var biometricService = BiometricService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appViewModel)
                .environmentObject(notificationService)
                .environmentObject(biometricService)
                .preferredColorScheme(.light)
        }
    }
}
