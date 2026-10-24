import SwiftUI

@MainActor
public final class BlinkToastState: ObservableObject {
    public static let shared = BlinkToastState()

    @Published public var remainingSeconds: Double = 5.0
    @Published public var totalSeconds: Double = 5.0
    @Published public var isEyeClosed: Bool = false
    @Published public var isVisible: Bool = false
    @Published public var glowIntensity: Double = 0.5

    private var countdownTask: Task<Void, Never>?

    public init() {}

    public func start(duration: Double = 5.0, onComplete: @escaping @MainActor () -> Void) {
        remainingSeconds = duration
        totalSeconds = duration
        isEyeClosed = false
        isVisible = true
        glowIntensity = 0.5

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
                Capsule()
                    .fill(isLight ? Color.white.opacity(0.95) : Color(red: 0.11, green: 0.12, blue: 0.15).opacity(0.96))
                    .overlay(
                        Capsule()
                            .stroke(
                                settings.ambientGlowEnabled
                                    ? (isLight
                                        ? LinearGradient(colors: [Color.cyan.opacity(0.50), Color.cyan.opacity(0.20)], startPoint: .top, endPoint: .bottom)
                                        : LinearGradient(colors: [Color.cyan.opacity(0.75), Color.cyan.opacity(0.30)], startPoint: .top, endPoint: .bottom))
                                    : (isLight
                                        ? LinearGradient(colors: [Color.black.opacity(0.12), Color.black.opacity(0.04)], startPoint: .top, endPoint: .bottom)
                                        : LinearGradient(colors: [Color.white.opacity(0.28), Color.white.opacity(0.08)], startPoint: .top, endPoint: .bottom)),
                                lineWidth: settings.ambientGlowEnabled ? 1.2 : 1.0
                            )
                    )
                    // Layer 1: Ambient outer cyan radiance (glows and softly breathes to catch peripheral vision)
                    .shadow(
                        color: settings.ambientGlowEnabled
                            ? Color.cyan.opacity(isLight ? (0.28 + 0.18 * effectiveGlow) : (0.35 + 0.30 * effectiveGlow))
                            : Color.clear,
                        radius: settings.ambientGlowEnabled ? CGFloat(12.0 + 10.0 * effectiveGlow) : 0,
                        x: 0,
                        y: isLight ? 2 : 4
                    )
                    // Layer 2: Wider diffused mint/teal haze
                    .shadow(
                        color: settings.ambientGlowEnabled
                            ? Color.mint.opacity(isLight ? (0.12 + 0.10 * effectiveGlow) : (0.18 + 0.18 * effectiveGlow))
                            : Color.clear,
                        radius: settings.ambientGlowEnabled ? CGFloat(20.0 + 14.0 * effectiveGlow) : 0,
                        x: 0,
                        y: 0
                    )
                    // Layer 3: Physical grounding elevation shadow
                    .shadow(
                        color: isLight ? Color.black.opacity(0.12) : Color.black.opacity(0.50),
                        radius: isLight ? 6 : 10,
                        x: 0,
                        y: isLight ? 3 : 5
                    )
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}
