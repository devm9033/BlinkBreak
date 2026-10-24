import SwiftUI
import AppKit

@MainActor
public final class BlinkScreenEffectState: ObservableObject {
    public static let shared = BlinkScreenEffectState()

    @Published public var progress: Double = 0.0
    @Published public var washOpacity: Double = 0.0
    @Published public var ringOpacity: Double = 0.0
    @Published public var isRunning: Bool = false

    private var animationTask: Task<Void, Never>?

    private init() {}

    public func reset() {
        progress = 0.0
        washOpacity = 0.0
        ringOpacity = 0.0
        isRunning = false
        animationTask?.cancel()
        animationTask = nil
    }

    public func start(
        duration: Double = 0.82,
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

                // iPhone unlock caustic profile:
                // Fast bloom in (0.0 -> 0.22s), sustained refraction sweep, smooth decay
                if t < 0.24 {
                    let easeIn = t / 0.24
                    self.washOpacity = easeIn
                    self.ringOpacity = easeIn
                } else if t < 0.58 {
                    self.washOpacity = 1.0 - ((t - 0.24) / 0.34) * 0.35 // 1.0 down to 0.65
                    self.ringOpacity = 1.0
                } else {
                    let decay = (t - 0.58) / 0.42
                    self.washOpacity = max(0, 0.65 * (1.0 - decay))
                    self.ringOpacity = max(0, 1.0 - decay)
                }

                // Seamless handoff: as the glass ring contracts into the notch area, spring the pill
                if t >= 0.50 && !pillTriggered {
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

    private let notchHeight: CGFloat

    public init(screenFrame: NSRect) {
        if let screen = NSScreen.main, screen.safeAreaInsets.top > 0 {
            self.notchHeight = screen.safeAreaInsets.top
        } else {
            self.notchHeight = 28.0
        }
    }

    private var isLight: Bool {
        if colorScheme == .light { return true }
        if let appearance = NSApp.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]), appearance == .aqua {
            return true
        }
        return false
    }

    public var body: some View {
        GeometryReader { geometry in
            let p = state.progress
            // Smooth S-curve easing for natural liquid inertia
            let t = p < 0.5 ? 4.0 * p * p * p : 1.0 - pow(-2.0 * p + 2.0, 3.0) / 2.0

            let startWidth = geometry.size.width * 0.72
            let targetWidth: CGFloat = 220.0
            let currentWidth = startWidth + (targetWidth - startWidth) * CGFloat(t)

            let startHeight = geometry.size.height * 0.55
            let targetHeight: CGFloat = 42.0
            let currentHeight = startHeight + (targetHeight - startHeight) * CGFloat(t)

            let startY = geometry.size.height * 0.50
            let targetY = notchHeight + 26.0
            let currentY = startY + (targetY - startY) * CGFloat(t)

            ZStack {
                // 1. Fullscreen Ambient Caustic Wash (Apple lock screen wake sheen)
                // Crystalline, transparent, zero obstruction of active work
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.05, green: 0.85, blue: 1.00).opacity((isLight ? 0.12 : 0.22) * state.washOpacity),
                        Color(red: 0.58, green: 0.38, blue: 0.98).opacity((isLight ? 0.08 : 0.16) * state.washOpacity),
                        Color(red: 0.96, green: 0.30, blue: 0.65).opacity((isLight ? 0.04 : 0.09) * state.washOpacity),
                        Color.clear
                    ]),
                    center: UnitPoint(x: 0.5, y: 0.04),
                    startRadius: 15,
                    endRadius: max(geometry.size.width, geometry.size.height) * 0.78
                )
                .ignoresSafeArea()

                // 2. Converging Specular Liquid Glass Ring
                if !reduceMotion {
                    // Outer Caustic Aurora Ring
                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.05, green: 0.85, blue: 1.00), // Electric Cyan
                                    Color(red: 0.58, green: 0.38, blue: 0.98), // Royal Indigo
                                    Color(red: 0.96, green: 0.30, blue: 0.65), // Apple Rose
                                    Color(red: 0.15, green: 0.92, blue: 0.65), // Radiant Mint
                                    Color(red: 0.05, green: 0.85, blue: 1.00)  // Loop to Cyan
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: max(1.2, 2.8 * (1.0 - CGFloat(t) * 0.45))
                        )
                        .frame(width: max(24, currentWidth), height: max(12, currentHeight))
                        .position(x: geometry.size.width / 2, y: currentY)
                        .shadow(
                            color: Color(red: 0.05, green: 0.85, blue: 1.00).opacity(0.45 * state.ringOpacity),
                            radius: 14,
                            x: 0,
                            y: 0
                        )
                        .opacity(state.ringOpacity)

                    // Inner Specular Glass Reflection Edge (Optics Depth)
                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                        .strokeBorder(
                            Color.white.opacity((isLight ? 0.40 : 0.60) * state.ringOpacity),
                            lineWidth: 0.8
                        )
                        .frame(width: max(18, currentWidth - 10), height: max(8, currentHeight - 8))
                        .position(x: geometry.size.width / 2, y: currentY)
                        .opacity(state.ringOpacity * 0.75)
                }
            }
        }
        .ignoresSafeArea()
    }
}
