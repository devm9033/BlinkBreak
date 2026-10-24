import SwiftUI

@MainActor
public final class BreakOverlayViewState: ObservableObject {
    public static let shared = BreakOverlayViewState()

    @Published public var hasAppeared: Bool = false
    @Published public var breatheScale: Double = 1.0

    private var animationTask: Task<Void, Never>?

    private init() {}

    public func reset() {
        hasAppeared = false
        animationTask?.cancel()
        animationTask = nil
    }

    public func appear() {
        hasAppeared = true
        breatheScale = 1.0

        animationTask?.cancel()
        animationTask = Task { @MainActor [weak self] in
            let step: Double = 0.05
            var elapsed: Double = 0.0
            while true {
                try? await Task.sleep(nanoseconds: 50_000_000)
                if Task.isCancelled { return }
                guard let self = self, self.hasAppeared else { return }

                elapsed += step

                // 4.5s box-breathing cycle (calm, organic scale 1.0 ... 1.025)
                let breatheWave = sin((elapsed / 2.25) * .pi)
                self.breatheScale = 1.0 + 0.025 * ((breatheWave + 1.0) / 2.0)
            }
        }
    }
}

public struct BreakOverlayView: View {
    @ObservedObject var breakManager = BreakManager.shared
    @ObservedObject var viewState = BreakOverlayViewState.shared
    @ObservedObject var settings = AppSettings.shared
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var onSkip: () -> Void
    var onSnooze: () -> Void

    public init(onSkip: @escaping () -> Void, onSnooze: @escaping () -> Void) {
        self.onSkip = onSkip
        self.onSnooze = onSnooze
    }

    private var isLight: Bool {
        colorScheme == .light
    }

    private var progress: Double {
        guard breakManager.totalBreakDuration > 0 else { return 0 }
        return Double(breakManager.breakRemainingSeconds) / Double(breakManager.totalBreakDuration)
    }

    public var body: some View {
        ZStack {
            // Adaptive fullscreen dimming backdrop with frosted blur
            (isLight ? Color.black.opacity(0.38) : Color.black.opacity(0.68))
                .background(.ultraThinMaterial)
                .ignoresSafeArea()

            // The Floating Apple Rest Plaque
            VStack(spacing: 26) {
                // Header badge: Frosted micro-capsule
                HStack(spacing: 7) {
                    Circle()
                        .fill(Color.cyan)
                        .frame(width: 6, height: 6)
                    Text("EYE REST BREAK")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(1.4)
                        .foregroundColor(.cyan)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isLight ? Color.cyan.opacity(0.12) : Color.white.opacity(0.10))
                        .overlay(
                            Capsule()
                                .strokeBorder(isLight ? Color.cyan.opacity(0.28) : Color.white.opacity(0.18), lineWidth: 0.5)
                        )
                )

                // Circular Progress Ring (Clean luminous gradient arc — no boxy clipping)
                ZStack {
                    Circle()
                        .stroke(isLight ? Color.black.opacity(0.08) : Color.white.opacity(0.12), lineWidth: 8)
                        .frame(width: 170, height: 170)

                    Circle()
                        .trim(from: 0, to: CGFloat(progress))
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.10, green: 0.85, blue: 1.00), // Electric Cyan
                                    Color(red: 0.45, green: 0.60, blue: 1.00), // Calm Royal Blue
                                    Color(red: 0.20, green: 0.88, blue: 0.70)  // Soft Mint
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 170, height: 170)
                        .rotationEffect(.degrees(-90))
                        .animation(reduceMotion ? .none : .linear(duration: 1.0), value: progress)
                        .shadow(color: Color.cyan.opacity(0.35), radius: 8, x: 0, y: 0)

                    VStack(spacing: 2) {
                        Text("\(breakManager.breakRemainingSeconds)")
                            .font(.system(size: 52, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(isLight ? .primary : .white)
                        Text("seconds")
                            .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                            .textCase(.uppercase)
                            .tracking(1.5)
                            .foregroundColor(isLight ? .secondary : .white.opacity(0.70))
                    }
                }

                // Guidance text with high contrast
                VStack(spacing: 8) {
                    Text("Look 20 feet away")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .tracking(-0.4)
                        .foregroundColor(isLight ? .primary : .white)

                    Text("Shift your focus to a distant object across the room or outside a window.\nBlink softly and relax your facial muscles.")
                        .font(.system(size: 14, weight: .regular))
                        .lineSpacing(3)
                        .multilineTextAlignment(.center)
                        .foregroundColor(isLight ? .secondary : .white.opacity(0.85))
                        .frame(maxWidth: 420)
                }

                // Frosted Action Buttons
                HStack(spacing: 16) {
                    Button(action: {
                        HapticManager.shared.buttonClick()
                        onSnooze()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "clock.arrow.circlepath")
                            Text("Snooze (5m)")
                        }
                    }
                    .buttonStyle(AppleTactileButtonStyle(isDestructive: false))

                    Button(action: {
                        HapticManager.shared.dismissClick()
                        onSkip()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark")
                            Text("Skip Break (Esc)")
                        }
                    }
                    .buttonStyle(AppleTactileButtonStyle(isDestructive: true))
                }
                .padding(.top, 4)
            }
            .padding(38)
            .background(
                // Pure, seamless frosted glass card — zero boxy gradient cutoff, zero glare refraction
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(
                        isLight
                            ? Color(red: 0.98, green: 0.98, blue: 1.00).opacity(0.92)
                            : Color(red: 0.09, green: 0.10, blue: 0.13).opacity(0.94)
                    )
                    .overlay(
                        // Quiet, seamless uniform Apple hairline border
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .stroke(
                                isLight
                                    ? Color.black.opacity(0.08)
                                    : Color.white.opacity(0.12),
                                lineWidth: 1.0
                            )
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .shadow(
                color: isLight ? Color.black.opacity(0.18) : Color.black.opacity(0.55),
                radius: isLight ? 28 : 40,
                x: 0,
                y: isLight ? 12 : 18
            )
            // 4.5s Box-Breathing organic scale
            .scaleEffect(reduceMotion ? 1.0 : (viewState.hasAppeared ? viewState.breatheScale : 0.95))
            .opacity(viewState.hasAppeared ? 1.0 : 0.0)
            .animation(
                reduceMotion ? .easeOut(duration: 0.15) : .spring(response: 0.36, dampingFraction: 0.84),
                value: viewState.hasAppeared
            )
        }
        .onAppear {
            BreakOverlayViewState.shared.appear()
        }
    }
}
