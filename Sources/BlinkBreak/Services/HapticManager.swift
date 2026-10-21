import AppKit

@MainActor
public final class HapticManager {
    public static let shared = HapticManager()

    private init() {}

    /// Subtle alignment tick when snapping across slider intervals (Force Touch trackpad)
    public func sliderTick() {
        NSHapticFeedbackManager.defaultPerformer.perform(
            .alignment,
            performanceTime: .default
        )
    }

    /// Haptic feedback for button presses or mode changes
    public func buttonClick() {
        NSHapticFeedbackManager.defaultPerformer.perform(
            .levelChange,
            performanceTime: .default
        )
    }
}
