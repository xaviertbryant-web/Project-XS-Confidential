import LocalAuthentication
import SwiftUI

class BiometricService: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var biometricType: LABiometryType = .none

    init() {
        checkBiometricType()
    }

    func checkBiometricType() {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            biometricType = context.biometryType
        }
    }

    func authenticate(reason: String) async -> Bool {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else { return false }
        do {
            let result = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
            await MainActor.run { self.isAuthenticated = result }
            return result
        } catch {
            return false
        }
    }

    var biometricIconName: String {
        switch biometricType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        default: return "lock.fill"
        }
    }

    var biometricName: String {
        switch biometricType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        default: return "Passcode"
        }
    }
}
