import SwiftUI

@MainActor
public final class BlinkToastState: ObservableObject {
    public static let shared = BlinkToastState()

    @Published public var remainingSeconds: Double = 5.0
    @Published public var totalSeconds: Double = 5.0
    @Published public var isEyeClosed: Bool = false
    @Published public var isVisible: Bool = false
    @Published public var glowIntensity: Double = 0.5
    @Published public var glowAngle: Double = 0.0

    private var countdownTask: Task<Void, Never>?

    public init() {}

    public func start(duration: Double = 5.0, onComplete: @escaping @MainActor () -> Void) {
        remainingSeconds = duration
        totalSeconds = duration
        isEyeClosed = false
        isVisible = true
        glowIntensity = 0.5
        glowAngle = 0.0

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

                // Organic blinking rhythm: closes for ~200ms every 0.9s
                let cycleTime = elapsed.truncatingRemainder(dividingBy: 0.9)
                self.isEyeClosed = (cycleTime < 0.22)

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
                // Animated Eye Glyph
                ZStack {
                    Circle()
                        .fill(Color.cyan.opacity(isLight ? 0.16 : 0.24))
                        .frame(width: 28, height: 28)

                    Image(systemName: "eye.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.cyan)
                        .opacity(state.isEyeClosed ? 0.0 : 1.0)
                        .scaleEffect(state.isEyeClosed ? 0.85 : 1.0)

                    Image(systemName: "eye.slash.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.cyan)
                        .opacity(state.isEyeClosed ? 1.0 : 0.0)
                        .scaleEffect(state.isEyeClosed ? 1.0 : 0.85)
                }
                .animation(reduceMotion ? .none : .easeInOut(duration: 0.18), value: state.isEyeClosed)

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
                ZStack {
                    if settings.ambientGlowEnabled {
                        // Multi-color aura Layer 1: Wider soft halo hugging pill contour in 360°
                        Capsule()
                            .stroke(
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
                                ),
                                lineWidth: 8
                            )
                            .blur(radius: CGFloat(10.0 + 4.0 * effectiveGlow))
                            .opacity(isLight ? 0.45 : (0.50 + 0.35 * effectiveGlow))

                        // Multi-color aura Layer 2: Tight concentric contour halo
                        Capsule()
                            .stroke(
                                AngularGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.05, green: 0.85, blue: 1.00),
                                        Color(red: 0.58, green: 0.38, blue: 0.98),
                                        Color(red: 0.96, green: 0.32, blue: 0.68),
                                        Color(red: 0.15, green: 0.88, blue: 0.62),
                                        Color(red: 0.05, green: 0.85, blue: 1.00)
                                    ]),
                                    center: .center,
                                    angle: .degrees(state.glowAngle)
                                ),
                                lineWidth: 3.5
                            )
                            .blur(radius: CGFloat(4.0 + 2.0 * effectiveGlow))
                            .opacity(isLight ? 0.70 : (0.75 + 0.25 * effectiveGlow))
                    }

                    // Main Capsule Solid Body
                    Capsule()
                        .fill(isLight ? Color.white.opacity(0.96) : Color(red: 0.11, green: 0.12, blue: 0.15).opacity(0.97))
                        .overlay(
                            Capsule()
                                .strokeBorder(
                                    settings.ambientGlowEnabled
                                        ? AnyShapeStyle(
                                            AngularGradient(
                                                gradient: Gradient(colors: [
                                                    Color(red: 0.20, green: 0.90, blue: 1.00),
                                                    Color(red: 0.68, green: 0.48, blue: 1.00),
                                                    Color(red: 1.00, green: 0.45, blue: 0.75),
                                                    Color(red: 0.30, green: 0.95, blue: 0.70),
                                                    Color(red: 0.20, green: 0.90, blue: 1.00)
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
                                    lineWidth: settings.ambientGlowEnabled ? 1.4 : 1.0
                                )
                        )
                        // Clean physical grounding elevation shadow
                        .shadow(
                            color: isLight ? Color.black.opacity(0.12) : Color.black.opacity(0.50),
                            radius: isLight ? 4 : 8,
                            x: 0,
                            y: isLight ? 2 : 3
                        )
                }
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}
