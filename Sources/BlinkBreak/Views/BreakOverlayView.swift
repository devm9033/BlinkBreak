import SwiftUI

@MainActor
public final class BreakOverlayViewState: ObservableObject {
    public static let shared = BreakOverlayViewState()
    @Published public var hasAppeared: Bool = false

    private init() {}

    public func reset() {
        hasAppeared = false
    }

    public func appear() {
        hasAppeared = true
    }
}

public struct BreakOverlayView: View {
    @ObservedObject var breakManager = BreakManager.shared
    @ObservedObject var viewState = BreakOverlayViewState.shared
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
            (isLight ? Color.black.opacity(0.38) : Color.black.opacity(0.72))
                .background(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 26) {
                // Header badge
                HStack(spacing: 8) {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 13, weight: .bold))
                    Text("EYE REST BREAK")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .tracking(1.4)
                }
                .foregroundColor(.cyan)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(isLight ? Color.cyan.opacity(0.14) : Color.cyan.opacity(0.18))
                .clipShape(Capsule())

                // Circular Progress Ring
                ZStack {
                    Circle()
                        .stroke(isLight ? Color.black.opacity(0.08) : Color.white.opacity(0.12), lineWidth: 8)
                        .frame(width: 160, height: 160)

                    Circle()
                        .trim(from: 0, to: CGFloat(progress))
                        .stroke(
                            LinearGradient(
                                colors: [Color.cyan, Color.blue, Color.mint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 160, height: 160)
                        .rotationEffect(.degrees(-90))
                        .animation(reduceMotion ? .none : .linear(duration: 1.0), value: progress)

                    VStack(spacing: 2) {
                        Text("\(breakManager.breakRemainingSeconds)")
                            .font(.system(size: 50, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(isLight ? .primary : .white)
                        Text("seconds")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(isLight ? .secondary : .white.opacity(0.72))
                    }
                }

                // Guidance text with high contrast in both Light and Dark themes
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

                // Action buttons with tactile press feedback and adaptive colors
                HStack(spacing: 16) {
                    Button(action: onSnooze) {
                        HStack(spacing: 6) {
                            Image(systemName: "clock.arrow.circlepath")
                            Text("Snooze (5m)")
                        }
                    }
                    .buttonStyle(AppleTactileButtonStyle(isDestructive: false))

                    Button(action: onSkip) {
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
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(isLight ? Color.white.opacity(0.92) : Color(red: 0.12, green: 0.13, blue: 0.16).opacity(0.95))
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(
                                isLight
                                    ? LinearGradient(colors: [Color.black.opacity(0.10), Color.black.opacity(0.04)], startPoint: .top, endPoint: .bottom)
                                    : LinearGradient(colors: [Color.white.opacity(0.24), Color.white.opacity(0.08)], startPoint: .top, endPoint: .bottom),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: isLight ? Color.black.opacity(0.18) : Color.black.opacity(0.50),
                        radius: isLight ? 28 : 36,
                        x: 0,
                        y: isLight ? 12 : 18
                    )
            )
            .frame(maxWidth: 520)
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
