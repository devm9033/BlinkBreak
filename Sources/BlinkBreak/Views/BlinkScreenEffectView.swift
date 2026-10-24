import SwiftUI
import AppKit

@MainActor
public final class BlinkScreenEffectState: ObservableObject {
    public static let shared = BlinkScreenEffectState()

    @Published public var progress: Double = 0.0
    @Published public var glowOpacity: Double = 0.0
    @Published public var isRunning: Bool = false

    // Compatibility aliases for tests
    public var washOpacity: Double { glowOpacity }
    public var ringOpacity: Double { glowOpacity }

    private var animationTask: Task<Void, Never>?

    private init() {}

    public func reset() {
        progress = 0.0
        glowOpacity = 0.0
        isRunning = false
        animationTask?.cancel()
        animationTask = nil
    }

    public func start(
        duration: Double = 0.85,
        onPillTrigger: @escaping @MainActor () -> Void,
        onComplete: @escaping @MainActor () -> Void
    ) {
        reset()
        isRunning = true

        animationTask = Task { @MainActor [weak self] in
            let fps: Double = 60.0
            let stepInterval = 1.0 / fps
            let totalSteps = max(1, Int(duration * fps))
            var step = 0
            var pillTriggered = false

            while step <= totalSteps {
                try? await Task.sleep(nanoseconds: UInt64(stepInterval * 1_000_000_000))
                if Task.isCancelled { return }
                guard let self = self, self.isRunning else { return }

                step += 1
                let t = min(1.0, Double(step) / Double(totalSteps))
                self.progress = t

                // Subtle edge glow: smooth bloom into peak, brief gentle hold, and quiet decay
                if t < 0.28 {
                    self.glowOpacity = t / 0.28
                } else if t < 0.55 {
                    self.glowOpacity = 1.0 - ((t - 0.28) / 0.27) * 0.20 // stays luminous (0.80 - 1.0)
                } else {
                    let decay = (t - 0.55) / 0.45
                    self.glowOpacity = max(0, 0.80 * (1.0 - decay))
                }

                // Trigger the pill drop right at the peak glow (~0.30s)
                if t >= 0.30 && !pillTriggered {
                    pillTriggered = true
                    HapticManager.shared.pillHover()
                    onPillTrigger()
                }
            }

            guard let self = self, !Task.isCancelled else { return }
            self.reset()
            onComplete()
        }
    }
}

public struct BlinkScreenEffectView: View {
    @ObservedObject var state = BlinkScreenEffectState.shared
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    public init(screenFrame: NSRect) {}

    private var isLight: Bool {
        if colorScheme == .light { return true }
        if let appearance = NSApp.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]), appearance == .aqua {
            return true
        }
        return false
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                if !reduceMotion {
                    // Deep diffused edge halo (Apple Intelligence style ambient perimeter light)
                    // The center of the screen is 100% empty and transparent!
                    Rectangle()
                        .strokeBorder(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.05, green: 0.85, blue: 1.00), // Electric Cyan
                                    Color(red: 0.58, green: 0.38, blue: 0.98), // Royal Indigo
                                    Color(red: 0.96, green: 0.30, blue: 0.65), // Apple Rose
                                    Color(red: 0.15, green: 0.92, blue: 0.65), // Radiant Mint
                                    Color(red: 0.05, green: 0.85, blue: 1.00)  // Loop to Cyan
                                ]),
                                center: .center
                            ),
                            lineWidth: 26.0
                        )
                        .blur(radius: 28.0)
                        .opacity(state.glowOpacity * (isLight ? 0.40 : 0.60))

                    // Medium edge rim for crisp gradient definition along the screen bezels
                    Rectangle()
                        .strokeBorder(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.05, green: 0.85, blue: 1.00),
                                    Color(red: 0.58, green: 0.38, blue: 0.98),
                                    Color(red: 0.96, green: 0.30, blue: 0.65),
                                    Color(red: 0.15, green: 0.92, blue: 0.65),
                                    Color(red: 0.05, green: 0.85, blue: 1.00)
                                ]),
                                center: .center
                            ),
                            lineWidth: 5.0
                        )
                        .blur(radius: 6.0)
                        .opacity(state.glowOpacity * (isLight ? 0.35 : 0.50))

                    // Subtle specular bezel highlight line
                    Rectangle()
                        .strokeBorder(
                            Color.white.opacity(isLight ? 0.20 : 0.35),
                            lineWidth: 1.0
                        )
                        .opacity(state.glowOpacity * 0.65)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .ignoresSafeArea()
    }
}
