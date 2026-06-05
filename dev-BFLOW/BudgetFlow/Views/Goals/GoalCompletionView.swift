import SwiftUI

struct GoalCompletionView: View {
    let goal: Goal
    @Environment(\.dismiss) var dismiss
    @State private var showContent = false
    @State private var confettiCount = 0
    @State private var particles: [ConfettiParticle] = []

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            // Confetti particles
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
            }

            VStack(spacing: 32) {
                Spacer()

                if showContent {
                    ZStack {
                        Circle()
                            .fill(LinearGradient.brandSubtle)
                            .frame(width: 140, height: 140)

                        Text(goal.emoji)
                            .font(.system(size: 64))
                    }
                    .scaleEffect(showContent ? 1.0 : 0.3)
                    .transition(.scale.combined(with: .opacity))

                    VStack(spacing: 12) {
                        Text("Goal Crushed! 🔥")
                            .font(.system(size: 32, weight: .black))
                            .foregroundColor(.textPrimary)

                        Text(goal.title)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(LinearGradient.brand)

                        Text("You did it! You saved\n$\(String(format: "%.0f", goal.targetAmount)) for \(goal.title).")
                            .font(.system(size: 16))
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))

                    VStack(spacing: 12) {
                        motivationalQuote
                        streakBadge
                    }
                    .padding(.horizontal, 32)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Spacer()

                PrimaryButton(title: "Keep Going! 💪") {
                    dismiss()
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
                .opacity(showContent ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showContent = true
            }
            spawnConfetti()
        }
    }

    var motivationalQuote: some View {
        VStack(spacing: 8) {
            Text("\"Success is the sum of small efforts, repeated day in and day out.\"")
                .font(.system(size: 14, weight: .medium, design: .serif))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .italic()
        }
        .padding(16)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    var streakBadge: some View {
        HStack(spacing: 12) {
            Image(systemName: "flame.fill")
                .foregroundColor(.brandOrange)
                .font(.system(size: 24))
            VStack(alignment: .leading, spacing: 2) {
                Text("Goal Achiever")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.textPrimary)
                Text("You're in the top 10% of savers this month!")
                    .font(.system(size: 12))
                    .foregroundColor(.textSecondary)
            }
            Spacer()
        }
        .padding(16)
        .background(Color.brandOrange.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    func spawnConfetti() {
        let colors: [Color] = [.brandOrange, .brandRed, .successGreen, .brandAmber, .blue, .purple]
        particles = (0..<60).map { _ in
            ConfettiParticle(
                color: colors.randomElement()!,
                position: CGPoint(x: CGFloat.random(in: 0...400), y: CGFloat.random(in: -50...200)),
                size: CGFloat.random(in: 6...14),
                opacity: Double.random(in: 0.6...1.0)
            )
        }
        withAnimation(.easeOut(duration: 2.5)) {
            particles = particles.map { particle in
                var p = particle
                p.position.y += CGFloat.random(in: 400...700)
                p.opacity = 0
                return p
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    var color: Color
    var position: CGPoint
    var size: CGFloat
    var opacity: Double
}

struct ApplePayLockOverlay: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var biometricService: BiometricService
    @State private var pin = ""
    @State private var shakeOffset: CGFloat = 0

    private var hasPINSet: Bool { !appViewModel.profile.applePayPIN.isEmpty }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                LinearGradient.brand.ignoresSafeArea()

                VStack(spacing: 24) {
                    HStack {
                        Button { withAnimation { appViewModel.showApplePayLock = false } } label: {
                            Image(systemName: "xmark").foregroundColor(.white).font(.system(size: 18, weight: .semibold))
                        }
                        Spacer()
                        Text("Apple Pay").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                        Spacer()
                        Color.clear.frame(width: 24)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 60)

                    Image(systemName: "wave.3.right.circle.fill")
                        .font(.system(size: 72))
                        .foregroundColor(.white)

                    Text("Confirm your identity")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)

                    if hasPINSet {
                        PINDotsView(filledCount: pin.count)
                            .offset(x: shakeOffset)

                        NumberPadView(pin: $pin, maxDigits: 6) { enteredPIN in
                            if enteredPIN == appViewModel.profile.applePayPIN {
                                withAnimation { appViewModel.showApplePayLock = false }
                            } else {
                                withAnimation(.default) { shakeOffset = 10 }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation(.default) { shakeOffset = -10 }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        withAnimation(.default) { shakeOffset = 0 }
                                        pin = ""
                                    }
                                }
                            }
                        }
                    } else {
                        Text("No PIN configured — use biometrics below\nor set a PIN in Settings.")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }

                    Button {
                        Task {
                            let authenticated = await biometricService.authenticate(reason: "Confirm Apple Pay payment")
                            if authenticated { withAnimation { appViewModel.showApplePayLock = false } }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: biometricService.biometricIconName)
                            Text("Use \(biometricService.biometricName)")
                        }
                        .foregroundColor(.white.opacity(0.85))
                        .font(.system(size: 15, weight: .medium))
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .ignoresSafeArea()
    }
}

struct PINDotsView: View {
    let filledCount: Int
    var total: Int = 6

    var body: some View {
        HStack(spacing: 16) {
            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(index < filledCount ? Color.white : Color.white.opacity(0.3))
                    .frame(width: 14, height: 14)
                    .scaleEffect(index < filledCount ? 1.2 : 1.0)
                    .animation(.spring(response: 0.2), value: filledCount)
            }
        }
    }
}

struct NumberPadView: View {
    @Binding var pin: String
    var maxDigits: Int = 6
    var onComplete: (String) -> Void

    let keys = [["1","2","3"],["4","5","6"],["7","8","9"],["","0","⌫"]]

    var body: some View {
        VStack(spacing: 12) {
            ForEach(keys, id: \.self) { row in
                HStack(spacing: 24) {
                    ForEach(row, id: \.self) { key in
                        Button {
                            if key == "⌫" {
                                if !pin.isEmpty { pin.removeLast() }
                            } else if !key.isEmpty {
                                if pin.count < maxDigits {
                                    pin += key
                                    if pin.count == maxDigits { onComplete(pin) }
                                }
                            }
                        } label: {
                            Text(key)
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 72, height: 72)
                                .background(key.isEmpty ? Color.clear : Color.white.opacity(0.15))
                                .clipShape(Circle())
                        }
                        .disabled(key.isEmpty)
                    }
                }
            }
        }
    }
}
