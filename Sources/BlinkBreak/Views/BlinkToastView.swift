import SwiftUI

@MainActor
public final class BlinkToastState: ObservableObject {
    public static let shared = BlinkToastState()

    @Published public var remainingSeconds: Double = 5.0
    @Published public var totalSeconds: Double = 5.0
    @Published public var isVisible: Bool = false
    @Published public var breatheScale: Double = 1.0
    @Published public var waveOffset1: CGSize = .zero
    @Published public var waveOffset2: CGSize = .zero
    @Published public var waveAngle1: Double = 0.0
    @Published public var waveAngle2: Double = 0.0

    // Backward-compatible properties
    @Published public var glowIntensity: Double = 0.5
    @Published public var glowAngle: Double = 0.0
    @Published public var irisScale: Double = 1.0

    private var countdownTask: Task<Void, Never>?

    public init() {}

    public func start(duration: Double = 5.0, onComplete: @escaping @MainActor () -> Void) {
        remainingSeconds = duration
        totalSeconds = duration
        isVisible = true
        breatheScale = 1.0
        waveOffset1 = .zero
        waveOffset2 = .zero
        waveAngle1 = 0.0
        waveAngle2 = 0.0
        glowIntensity = 0.5
        glowAngle = 0.0
        irisScale = 1.0

        countdownTask?.cancel()
        countdownTask = Task { @MainActor [weak self] in
            let step: Double = 0.05
            var elapsed: Double = 0.0
            while elapsed < duration {
                try? await Task.sleep(nanoseconds: 50_000_000)
                if Task.isCancelled { return }

                guard let self = self else { return }
                elapsed += step
                self.remainingSeconds = max(0, duration - elapsed)

                // Organic multi-axis fluid wave 1 (cyan + violet) - period ~7.0s
                let t1 = elapsed / 3.5
                self.waveOffset1 = CGSize(
                    width: sin(t1 * .pi * 2.0) * 35.0,
                    height: cos(t1 * .pi * 2.0 * 1.3) * 12.0
                )
                self.waveAngle1 = (elapsed * 45.0).truncatingRemainder(dividingBy: 360.0)

                // Organic multi-axis fluid wave 2 (mint + rose) - period ~8.5s
                let t2 = elapsed / 4.25
                self.waveOffset2 = CGSize(
                    width: cos(t2 * .pi * 2.0 * 0.9) * -30.0,
                    height: sin(t2 * .pi * 2.0 * 1.5) * 14.0
                )
                self.waveAngle2 = (elapsed * -38.0).truncatingRemainder(dividingBy: 360.0)

                // Whole-pill gentle breathing (period 3.2s, subtle 1.0 ... 1.035)
                let breatheWave = sin((elapsed / 1.6) * .pi)
                self.breatheScale = 1.0 + 0.035 * ((breatheWave + 1.0) / 2.0)

                // Backward-compatible updates
                self.glowIntensity = (breatheWave + 1.0) / 2.0
                self.glowAngle = self.waveAngle1
                self.irisScale = self.breatheScale
            }

            guard let self = self, !Task.isCancelled else { return }
            self.countdownTask = nil
            self.isVisible = false
            onComplete()
        }
    }

    public func stop() {
        countdownTask?.cancel()
        countdownTask = nil
        isVisible = false
    }
}

private struct TactileCircularButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1.0)
            .opacity(configuration.isPressed ? 0.70 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

public struct BlinkToastView: View {
    @ObservedObject var state = BlinkToastState.shared
    @ObservedObject var settings = AppSettings.shared
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    var onDismiss: () -> Void

    public init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
    }

    private var isLight: Bool {
        if colorScheme == .light { return true }
        if let appearance = NSApp.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]), appearance == .aqua {
            return true
        }
        return false
    }

    public var body: some View {
        ZStack(alignment: .center) {
            // Pure Borderless Liquid Glass Pill
            HStack(spacing: 8) {
                // Zen Typography: Just "Blink Eyes" (Adaptive to Light & Dark appearance)
                Text("Blink Eyes")
                    .font(.system(size: 13.5, weight: .bold, design: .rounded))
                    .foregroundColor(isLight ? Color(red: 0.10, green: 0.12, blue: 0.16) : .white)
                    .shadow(
                        color: isLight ? Color.white.opacity(0.80) : Color.black.opacity(0.40),
                        radius: 1.5,
                        x: 0,
                        y: 1
                    )

                // Frosted Circular Dismiss Button (Adaptive to Light & Dark appearance)
                Button(action: {
                    HapticManager.shared.dismissClick()
                    onDismiss()
                }) {
                    ZStack {
                        Circle()
                            .fill(isLight ? Color.black.opacity(0.08) : Color.white.opacity(0.16))
                            .overlay(
                                Circle()
                                    .strokeBorder(
                                        isLight ? Color.black.opacity(0.12) : Color.white.opacity(0.24),
                                        lineWidth: 0.5
                                    )
                            )
                            .frame(width: 19, height: 19)

                        Image(systemName: "xmark")
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundColor(
                                isLight
                                    ? Color(red: 0.15, green: 0.18, blue: 0.22).opacity(0.85)
                                    : Color.white.opacity(0.92)
                            )
                    }
                    .contentShape(Circle())
                }
                .buttonStyle(TactileCircularButtonStyle())
                .help("Dismiss reminder")
            }
            .padding(.leading, 14)
            .padding(.trailing, 8)
            .frame(height: 36)
            .background(
                ZStack {
                    // 1. Base Liquid Glass material (White Crystal Glass in Light Mode, Obsidian Glass in Dark Mode)
                    Capsule()
                        .fill(
                            isLight
                                ? Color(red: 0.96, green: 0.97, blue: 0.99).opacity(0.92)
                                : Color(red: 0.06, green: 0.07, blue: 0.09).opacity(0.92)
                        )

                    // 2. INTERNAL FLUID LIGHT WAVE (Aurora Wave: Cyan, Violet, Mint, Rose)
                    if settings.ambientGlowEnabled && !reduceMotion {
                        ZStack {
                            // Fluid Wave Blob 1: Cyan + Royal Violet
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.05, green: 0.85, blue: 1.00).opacity(isLight ? 0.45 : 0.70), // Electric Cyan
                                    Color(red: 0.58, green: 0.38, blue: 0.98).opacity(isLight ? 0.35 : 0.60), // Royal Indigo / Violet
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 55
                            )
                            .frame(width: 140, height: 60)
                            .offset(state.waveOffset1)
                            .rotationEffect(.degrees(state.waveAngle1))
                            .blur(radius: 12)

                            // Fluid Wave Blob 2: Radiant Mint + Apple Rose
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.15, green: 0.88, blue: 0.62).opacity(isLight ? 0.40 : 0.65), // Radiant Emerald Mint
                                    Color(red: 0.96, green: 0.32, blue: 0.68).opacity(isLight ? 0.30 : 0.50), // Apple Rose / Magenta
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 55
                            )
                            .frame(width: 140, height: 60)
                            .offset(state.waveOffset2)
                            .rotationEffect(.degrees(state.waveAngle2))
                            .blur(radius: 14)
                        }
                        .clipShape(Capsule())
                    }

                    // 3. Top Specular Rim Reflection Highlight (Apple Liquid Glass)
                    Capsule()
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    isLight ? Color.white.opacity(0.95) : Color.white.opacity(0.40),
                                    isLight ? Color.white.opacity(0.40) : Color.white.opacity(0.08),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1.0
                        )

                    // 4. Subtle Bottom Inner Shadow Edge for liquid glass depth
                    Capsule()
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    isLight ? Color.black.opacity(0.08) : Color.black.opacity(0.45)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1.0
                        )
                }
            )
            .clipShape(Capsule())
            // Natural elevation shadow (Adaptive in Light & Dark modes)
            .shadow(
                color: isLight ? Color.black.opacity(0.14) : Color.black.opacity(0.40),
                radius: 6,
                x: 0,
                y: 3
            )
            // Whole-pill organic breathing scale
            .scaleEffect(reduceMotion ? 1.0 : state.breatheScale)
            .onHover { isHovered in
                if isHovered {
                    HapticManager.shared.pillHover()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}
