import SwiftUI

@MainActor
public final class BlinkToastState: ObservableObject {
    public static let shared = BlinkToastState()

    @Published public var remainingSeconds: Double = 5.0
    @Published public var totalSeconds: Double = 5.0
    @Published public var isVisible: Bool = false
    @Published public var glowIntensity: Double = 0.5
    @Published public var glowAngle: Double = 0.0
    @Published public var irisScale: Double = 1.0

    private var countdownTask: Task<Void, Never>?

    public init() {}

    public func start(duration: Double = 5.0, onComplete: @escaping @MainActor () -> Void) {
        remainingSeconds = duration
        totalSeconds = duration
        isVisible = true
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

                // Smooth organic iris breathing
                let irisWave = sin((elapsed / 1.5) * .pi * 2.0)
                self.irisScale = (irisWave + 1.0) / 2.0

                // Smooth sinusoidal breathing aura (normalized 0.0 ... 1.0)
                let wave = sin((elapsed / 1.6) * .pi * 2.0)
                self.glowIntensity = (wave + 1.0) / 2.0

                // Smooth rotational shimmer around the pill contour (72 deg/sec = full 360° over 5s)
                self.glowAngle = (elapsed * 72.0).truncatingRemainder(dividingBy: 360.0)
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
        colorScheme == .light
    }

    private var progress: Double {
        guard state.totalSeconds > 0 else { return 0 }
        return state.remainingSeconds / state.totalSeconds
    }

    private var effectiveGlow: Double {
        if reduceMotion || !settings.ambientGlowEnabled {
            return 0.5
        }
        return state.glowIntensity
    }

    public var body: some View {
        ZStack(alignment: .center) {
            HStack(spacing: 11) {
                // Refined Apple Eye Glyph (Smooth Breathing Iris)
                ZStack {
                    Circle()
                        .fill(Color.cyan.opacity(isLight ? 0.16 : 0.22))
                        .frame(width: 28, height: 28)

                    Image(systemName: "eye.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.cyan)
                        .scaleEffect(reduceMotion ? 1.0 : (0.86 + 0.14 * state.irisScale))
                }

                // Direct, clear message (no wordy subtitles)
                Text("Blink Eyes")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(isLight ? .primary : .white)

                // Prominent, glanceable countdown timer ring
                ZStack {
                    Circle()
                        .stroke(isLight ? Color.black.opacity(0.10) : Color.white.opacity(0.16), lineWidth: 2.8)
                        .frame(width: 26, height: 26)

                    Circle()
                        .trim(from: 0, to: CGFloat(progress))
                        .stroke(
                            LinearGradient(colors: [.cyan, .mint], startPoint: .topLeading, endPoint: .bottomTrailing),
                            style: StrokeStyle(lineWidth: 2.8, lineCap: .round)
                        )
                        .frame(width: 26, height: 26)
                        .rotationEffect(.degrees(-90))

                    Text("\(max(1, Int(ceil(state.remainingSeconds))))")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(isLight ? .primary : .white)
                }
                .padding(.leading, 2)

                // Quick Dismiss Button
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundColor(isLight ? Color.black.opacity(0.40) : Color.white.opacity(0.50))
                        .padding(4)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .frame(height: 40)
            .background(
                Capsule()
                    .fill(isLight ? Color.white.opacity(0.96) : Color(red: 0.09, green: 0.10, blue: 0.13).opacity(0.97))
                    .overlay(
                        // Multi-color Apple Intelligence Illuminated Rim
                        Capsule()
                            .strokeBorder(
                                settings.ambientGlowEnabled
                                    ? AnyShapeStyle(
                                        AngularGradient(
                                            gradient: Gradient(colors: [
                                                Color(red: 0.05, green: 0.85, blue: 1.00), // Electric Cyan
                                                Color(red: 0.58, green: 0.38, blue: 0.98), // Royal Indigo
                                                Color(red: 0.96, green: 0.32, blue: 0.68), // Apple Rose / Magenta
                                                Color(red: 0.15, green: 0.88, blue: 0.62), // Radiant Mint
                                                Color(red: 0.05, green: 0.85, blue: 1.00)  // Loop to Cyan
                                            ]),
                                            center: .center,
                                            angle: .degrees(state.glowAngle)
                                        )
                                    )
                                    : AnyShapeStyle(
                                        isLight
                                            ? LinearGradient(colors: [Color.black.opacity(0.12), Color.black.opacity(0.04)], startPoint: .top, endPoint: .bottom)
                                            : LinearGradient(colors: [Color.white.opacity(0.28), Color.white.opacity(0.08)], startPoint: .top, endPoint: .bottom)
                                    ),
                                lineWidth: settings.ambientGlowEnabled ? 1.5 : 1.0
                            )
                    )
                    .overlay(
                        // Liquid Glass top specular highlight reflection
                        Capsule()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        isLight ? Color.white.opacity(0.70) : Color.white.opacity(0.25),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .center
                                ),
                                lineWidth: 1.0
                            )
                    )
                    // Contained luminous glow (hugs rim perfectly with zero boxy window clipping)
                    .shadow(
                        color: settings.ambientGlowEnabled
                            ? Color.cyan.opacity(isLight ? 0.30 : (0.35 + 0.15 * effectiveGlow))
                            : Color.clear,
                        radius: settings.ambientGlowEnabled ? CGFloat(9.0 + 3.0 * effectiveGlow) : 0,
                        x: 0,
                        y: 0
                    )
                    // Grounding elevation shadow
                    .shadow(
                        color: isLight ? Color.black.opacity(0.12) : Color.black.opacity(0.55),
                        radius: isLight ? 4 : 8,
                        x: 0,
                        y: isLight ? 2 : 4
                    )
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}
