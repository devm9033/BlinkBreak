import Testing
import Foundation
@testable import BlinkBreak

struct MockVideoDetector: VideoPlaybackDetecting {
    let isVideoPlaying: Bool
    let isDisplayOn: Bool
    let playingProcessName: String?

    func checkStatus() -> VideoPlaybackStatus {
        VideoPlaybackStatus(isVideoPlaying: isVideoPlaying, isDisplayOn: isDisplayOn, playingProcessName: playingProcessName)
    }
}

@Suite("BlinkBreak Tests")
@MainActor
struct BlinkBreakTests {

    @Test("App Settings default values")
    func appSettingsDefaults() {
        let settings = AppSettings.shared
        #expect(settings.isBreakEnabled == true)
        #expect(settings.isBlinkEnabled == true)
        #expect(settings.breakIntervalMinutes > 0)
        #expect(settings.breakDurationSeconds > 0)
        #expect(settings.blinkIntervalMinutes > 0)
        #expect(settings.blinkDurationSeconds > 0)
        #expect(settings.pauseBreaksDuringVideo == true)
        #expect(settings.pauseBlinksDuringVideo == false)
        #expect(settings.ambientGlowEnabled == true)
        #expect(settings.isPaused == false)
    }

    @Test("Pause and resume reminders")
    func pauseAndResume() {
        let settings = AppSettings.shared
        settings.pause(minutes: 15)
        #expect(settings.isPaused == true)
        #expect(settings.pauseUntil != nil)

        settings.resume()
        #expect(settings.isPaused == false)
        #expect(settings.pauseUntil == nil)
    }

    @Test("Ambient glow toggle persistence")
    func ambientGlowToggle() {
        let settings = AppSettings.shared
        settings.ambientGlowEnabled = false
        #expect(settings.ambientGlowEnabled == false)
        settings.ambientGlowEnabled = true
        #expect(settings.ambientGlowEnabled == true)
    }

    @Test("BreakManager duration formatting")
    func breakManagerDurationFormatting() {
        let manager = BreakManager.shared
        #expect(manager.formattedDuration(20) == "20s")
        #expect(manager.formattedDuration(65) == "01:05")
        #expect(manager.formattedDuration(120) == "02:00")
    }

    @Test("BreakManager break lifecycle")
    func breakManagerBreakCycle() {
        let manager = BreakManager.shared
        manager.resetTimers()

        manager.startBreak(forcedDuration: 10)
        #expect(manager.isBreakActive == true)
        #expect(manager.breakRemainingSeconds == 10)

        manager.snoozeBreak(minutes: 5)
        #expect(manager.isBreakActive == false)
        #expect(manager.timeUntilBreak == 300)

        manager.startBreak(forcedDuration: 5)
        manager.completeBreak()
        #expect(manager.isBreakActive == false)
        #expect(manager.timeUntilBreak == AppSettings.shared.breakIntervalMinutes * 60)
    }

    @Test("Blink trigger notification")
    func blinkTrigger() {
        let manager = BreakManager.shared
        var blinkNotified = false
        manager.onBlinkTriggered = {
            blinkNotified = true
        }

        manager.triggerBlink()
        #expect(blinkNotified == true)
        #expect(manager.timeUntilBlink == AppSettings.shared.blinkIntervalMinutes * 60)
    }

    @Test("BlinkScreenEffectState starts and resets cleanly")
    func blinkScreenEffectState() {
        let state = BlinkScreenEffectState.shared
        state.reset()
        #expect(state.progress == 0.0)
        #expect(state.isRunning == false)
        #expect(state.washOpacity == 0.0)
        #expect(state.ringOpacity == 0.0)
    }

    @Test("Video playback detection pauses break timer but NOT blink reminder")
    func videoPlaybackPausesBreakTimerOnly() {
        let manager = BreakManager.shared
        let settings = AppSettings.shared
        settings.pauseBreaksDuringVideo = true
        settings.resume()
        manager.resetTimers()

        let initialBreakTime = manager.timeUntilBreak
        let initialBlinkTime = manager.timeUntilBlink

        // Inject mock detector indicating video is playing in Safari
        manager.detector = MockVideoDetector(isVideoPlaying: true, isDisplayOn: true, playingProcessName: "Safari")

        manager.tick()

        #expect(manager.isVideoPlaying == true)
        #expect(manager.videoProcessName == "Safari")
        #expect(manager.isBreakPausedDueToVideo == true)
        #expect(manager.isBlinkPausedDueToVideo == false)

        // Break timer must be FROZEN (not decremented)
        #expect(manager.timeUntilBreak == initialBreakTime)

        // Blink reminder must CONTINUE counting down (decremented by 1)
        #expect(manager.timeUntilBlink == initialBlinkTime - 1)
    }

    @Test("Video playback pauses both break and blink reminders when both settings are enabled")
    func videoPlaybackPausesBothWhenBothEnabled() {
        let manager = BreakManager.shared
        let settings = AppSettings.shared
        settings.pauseBreaksDuringVideo = true
        settings.pauseBlinksDuringVideo = true
        settings.resume()
        manager.resetTimers()

        let initialBreakTime = manager.timeUntilBreak
        let initialBlinkTime = manager.timeUntilBlink

        manager.detector = MockVideoDetector(isVideoPlaying: true, isDisplayOn: true, playingProcessName: "Arc")

        manager.tick()

        #expect(manager.isVideoPlaying == true)
        #expect(manager.videoProcessName == "Arc")
        #expect(manager.isBreakPausedDueToVideo == true)
        #expect(manager.isBlinkPausedDueToVideo == true)

        // Both timers must be FROZEN
        #expect(manager.timeUntilBreak == initialBreakTime)
        #expect(manager.timeUntilBlink == initialBlinkTime)

        // Reset setting
        settings.pauseBlinksDuringVideo = false
    }

    @Test("Video playback pauses blink reminder only if break pausing is disabled")
    func videoPlaybackPausesBlinkOnly() {
        let manager = BreakManager.shared
        let settings = AppSettings.shared
        settings.pauseBreaksDuringVideo = false
        settings.pauseBlinksDuringVideo = true
        settings.resume()
        manager.resetTimers()

        let initialBreakTime = manager.timeUntilBreak
        let initialBlinkTime = manager.timeUntilBlink

        manager.detector = MockVideoDetector(isVideoPlaying: true, isDisplayOn: true, playingProcessName: "VLC")

        manager.tick()

        #expect(manager.isVideoPlaying == true)
        #expect(manager.videoProcessName == "VLC")
        #expect(manager.isBreakPausedDueToVideo == false)
        #expect(manager.isBlinkPausedDueToVideo == true)

        // Break timer decrements, blink timer is FROZEN
        #expect(manager.timeUntilBreak == initialBreakTime - 1)
        #expect(manager.timeUntilBlink == initialBlinkTime)

        // Reset settings
        settings.pauseBreaksDuringVideo = true
        settings.pauseBlinksDuringVideo = false
    }

    @Test("Video playback does NOT pause break timer if user setting is disabled")
    func videoPlaybackIgnoredWhenSettingDisabled() {
        let manager = BreakManager.shared
        let settings = AppSettings.shared
        settings.pauseBreaksDuringVideo = false
        settings.resume()
        manager.resetTimers()

        let initialBreakTime = manager.timeUntilBreak
        let initialBlinkTime = manager.timeUntilBlink

        manager.detector = MockVideoDetector(isVideoPlaying: true, isDisplayOn: true, playingProcessName: "QuickTime Player")

        manager.tick()

        #expect(manager.isVideoPlaying == true)
        #expect(manager.isBreakPausedDueToVideo == false)

        // Both timers must decrement because user explicitly disabled video pausing
        #expect(manager.timeUntilBreak == initialBreakTime - 1)
        #expect(manager.timeUntilBlink == initialBlinkTime - 1)

        // Reset setting
        settings.pauseBreaksDuringVideo = true
    }

    @Test("Normal countdown when no video is playing")
    func normalCountdownWhenNoVideo() {
        let manager = BreakManager.shared
        let settings = AppSettings.shared
        settings.pauseBreaksDuringVideo = true
        settings.resume()
        manager.resetTimers()

        let initialBreakTime = manager.timeUntilBreak
        let initialBlinkTime = manager.timeUntilBlink

        manager.detector = MockVideoDetector(isVideoPlaying: false, isDisplayOn: true, playingProcessName: nil)

        manager.tick()

        #expect(manager.isVideoPlaying == false)
        #expect(manager.isBreakPausedDueToVideo == false)
        #expect(manager.timeUntilBreak == initialBreakTime - 1)
        #expect(manager.timeUntilBlink == initialBlinkTime - 1)
    }

    @Test("Display sleep freezes all countdown timers")
    func displaySleepFreezesTimers() {
        let manager = BreakManager.shared
        manager.resetTimers()

        let initialBreakTime = manager.timeUntilBreak
        let initialBlinkTime = manager.timeUntilBlink

        // Inject mock detector indicating display is asleep
        manager.detector = MockVideoDetector(isVideoPlaying: false, isDisplayOn: false, playingProcessName: nil)

        manager.tick()

        // Timers must remain frozen when display is off
        #expect(manager.timeUntilBreak == initialBreakTime)
        #expect(manager.timeUntilBlink == initialBlinkTime)
    }

    @Test("Individual toggle disables break reminder countdown")
    func individualToggleDisablesBreakReminder() {
        let manager = BreakManager.shared
        let settings = AppSettings.shared
        settings.resume()
        settings.isBreakEnabled = false
        settings.isBlinkEnabled = true
        manager.resetTimers()

        let initialBreakTime = manager.timeUntilBreak
        let initialBlinkTime = manager.timeUntilBlink

        manager.detector = MockVideoDetector(isVideoPlaying: false, isDisplayOn: true, playingProcessName: nil)
        manager.tick()

        // Break timer must NOT decrement when disabled
        #expect(manager.timeUntilBreak == initialBreakTime)
        // Blink timer must decrement normally
        #expect(manager.timeUntilBlink == initialBlinkTime - 1)

        // Restore setting
        settings.isBreakEnabled = true
    }

    @Test("Individual toggle disables blink reminder countdown")
    func individualToggleDisablesBlinkReminder() {
        let manager = BreakManager.shared
        let settings = AppSettings.shared
        settings.resume()
        settings.isBreakEnabled = true
        settings.isBlinkEnabled = false
        manager.resetTimers()

        let initialBreakTime = manager.timeUntilBreak
        let initialBlinkTime = manager.timeUntilBlink

        manager.detector = MockVideoDetector(isVideoPlaying: false, isDisplayOn: true, playingProcessName: nil)
        manager.tick()

        // Break timer must decrement normally
        #expect(manager.timeUntilBreak == initialBreakTime - 1)
        // Blink timer must NOT decrement when disabled
        #expect(manager.timeUntilBlink == initialBlinkTime)

        // Restore setting
        settings.isBlinkEnabled = true
    }

    @Test("Live VideoPlaybackDetector runs without errors")
    func liveVideoDetectorRuns() {
        let detector = VideoPlaybackDetector.shared
        let status = detector.checkStatus()
        // Must return a boolean status and valid display check
        #expect(status.isDisplayOn == true || status.isDisplayOn == false)
    }
}
