import SwiftUI

@MainActor
public final class BreakOverlayViewState: ObservableObject {
    public static let shared = BreakOverlayViewState()

    @Published public var hasAppeared: Bool = false
    @Published public var glowAngle: Double = 0.0

    private var animationTask: Task<Void, Never>?

    private init() {}

    public func reset() {
        hasAppeared = false
        animationTask?.cancel()
        animationTask = nil
    }

    public func appear() {
        hasAppeared = true
        glowAngle = 0.0

        animationTask?.cancel()
        animationTask = Task { @MainActor [weak self] in
            let step: Double = 0.05
            var elapsed: Double = 0.0
            while true {
                try? await Task.sleep(nanoseconds: 50_000_000)
                if Task.isCancelled { return }
                guard let self = self, self.hasAppeared else { return }

                elapsed += step

                // Slow, peaceful rotational sweep around the window perimeter (~14.4s full revolution)
                self.glowAngle = (elapsed * 25.0).truncatingRemainder(dividingBy: 360.0)
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
            // 1. Adaptive fullscreen dimming backdrop with frosted blur
            (isLight ? Color.black.opacity(0.38) : Color.black.opacity(0.68))
                .background(.ultraThinMaterial)
                .ignoresSafeArea()

            // 2. Ambient Softly Moving Light Halo (BEHIND the window perimeter — 360° infinite diffusion)
            if settings.ambientGlowEnabled && !reduceMotion {
                RoundedRectangle(cornerRadius: 48, style: .continuous)
                    .fill(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.05, green: 0.85, blue: 1.00).opacity(0.60), // Electric Cyan
                                Color(red: 0.58, green: 0.38, blue: 0.98).opacity(0.50), // Royal Indigo
                                Color(red: 0.96, green: 0.32, blue: 0.68).opacity(0.40), // Apple Rose / Magenta
                                Color(red: 0.15, green: 0.88, blue: 0.62).opacity(0.55), // Emerald Mint
                                Color(red: 0.05, green: 0.85, blue: 1.00).opacity(0.60)  // Loop to Cyan
                            ]),
                            center: .center,
                            angle: .degrees(viewState.glowAngle)
                        )
                    )
                    .frame(width: 470, height: 490)
                    .blur(radius: 45)
                    .opacity(viewState.hasAppeared ? (isLight ? 0.35 : 0.70) : 0.0)
                    .animation(.easeIn(duration: 0.35), value: viewState.hasAppeared)
            }

            // 3. The 100% Static & Grounded Rest Plaque (Zero card scaling/wobbling)
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
            // Grounded static card: only scales gently on entry, then remains 100% static
            .scaleEffect(reduceMotion ? 1.0 : (viewState.hasAppeared ? 1.0 : 0.96))
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
