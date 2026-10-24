import Foundation
import Combine

@MainActor
public final class BreakManager: ObservableObject {
    public static let shared = BreakManager()

    private let settings = AppSettings.shared
    private var timer: Timer?

    @Published public private(set) var timeUntilBreak: Int = 0
    @Published public private(set) var timeUntilBlink: Int = 0
    @Published public private(set) var isBreakActive: Bool = false
    @Published public private(set) var breakRemainingSeconds: Int = 0
    @Published public private(set) var totalBreakDuration: Int = 20
    @Published public private(set) var isVideoPlaying: Bool = false
    @Published public private(set) var videoProcessName: String? = nil
    @Published public private(set) var isBreakPausedDueToVideo: Bool = false
    @Published public private(set) var isBlinkPausedDueToVideo: Bool = false

    public var detector: VideoPlaybackDetecting = VideoPlaybackDetector.shared

    public var onBreakStarted: (@MainActor (Int) -> Void)?
    public var onBreakTick: (@MainActor (Int, Int) -> Void)?
    public var onBreakEnded: (@MainActor () -> Void)?
    public var onBlinkTriggered: (@MainActor () -> Void)?
    public var onTick: (@MainActor () -> Void)?

    private init() {
        resetTimers()
        settings.onSettingsChanged = { [weak self] in
            self?.handleSettingsChanged()
        }
        startTimer()
    }

    public func resetTimers() {
        timeUntilBreak = settings.breakIntervalMinutes * 60
        timeUntilBlink = settings.blinkIntervalMinutes * 60
    }

    private func handleSettingsChanged() {
        let maxBreakSec = settings.breakIntervalMinutes * 60
        if timeUntilBreak > maxBreakSec {
            timeUntilBreak = maxBreakSec
        }

        let maxBlinkSec = settings.blinkIntervalMinutes * 60
        if timeUntilBlink > maxBlinkSec {
            timeUntilBlink = maxBlinkSec
        }
    }

    public func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
        if let t = timer {
            RunLoop.main.add(t, forMode: .common)
        }
    }

    public func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    public func tick() {
        settings.checkPauseStatus()
        guard !settings.isPaused else {
            onTick?()
            return
        }

        // Check video playback status
        let status = detector.checkStatus()
        self.isVideoPlaying = status.isVideoPlaying
        self.videoProcessName = status.playingProcessName
        self.isBreakPausedDueToVideo = status.isVideoPlaying && settings.pauseBreaksDuringVideo
        self.isBlinkPausedDueToVideo = status.isVideoPlaying && settings.pauseBlinksDuringVideo

        if isBreakActive {
            breakRemainingSeconds -= 1
            onBreakTick?(breakRemainingSeconds, totalBreakDuration)
            if breakRemainingSeconds <= 0 {
                completeBreak()
            }
        } else {
            // Only decrement break timer if not paused due to video playback
            if !isBreakPausedDueToVideo {
                timeUntilBreak -= 1
                if timeUntilBreak <= 0 {
                    startBreak()
                }
            }

            // Only decrement blink timer if not paused due to video playback
            if !isBlinkPausedDueToVideo {
                timeUntilBlink -= 1
                if timeUntilBlink <= 0 {
                    triggerBlink()
                }
            }
        }

        onTick?()
    }

    public func startBreak(forcedDuration: Int? = nil) {
        guard !isBreakActive else { return }

        isBreakActive = true
        totalBreakDuration = forcedDuration ?? settings.breakDurationSeconds
        breakRemainingSeconds = totalBreakDuration

        SoundManager.shared.playBreakStart()
        onBreakStarted?(totalBreakDuration)
    }

    public func completeBreak() {
        guard isBreakActive else { return }
        isBreakActive = false
        timeUntilBreak = settings.breakIntervalMinutes * 60
        SoundManager.shared.playBreakEnd()
        onBreakEnded?()
    }

    public func skipBreak() {
        guard isBreakActive else { return }
        isBreakActive = false
        timeUntilBreak = settings.breakIntervalMinutes * 60
        onBreakEnded?()
    }

    public func snoozeBreak(minutes: Int = 5) {
        isBreakActive = false
        timeUntilBreak = minutes * 60
        onBreakEnded?()
    }

    public func triggerBlink() {
        timeUntilBlink = settings.blinkIntervalMinutes * 60
        SoundManager.shared.playBlinkReminder()
        onBlinkTriggered?()
    }

    public func formattedDuration(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        if minutes > 0 {
            return String(format: "%02d:%02d", minutes, seconds)
        } else {
            return "\(seconds)s"
        }
    }
}
