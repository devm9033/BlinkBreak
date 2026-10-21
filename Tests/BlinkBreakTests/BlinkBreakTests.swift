import XCTest
@testable import BlinkBreak

@MainActor
final class BlinkBreakTests: XCTestCase {

    func testAppSettingsDefaults() {
        let settings = AppSettings.shared
        XCTAssertGreaterThan(settings.breakIntervalMinutes, 0)
        XCTAssertGreaterThan(settings.breakDurationSeconds, 0)
        XCTAssertGreaterThan(settings.blinkIntervalMinutes, 0)
        XCTAssertFalse(settings.isPaused)
    }

    func testPauseAndResume() {
        let settings = AppSettings.shared
        settings.pause(minutes: 15)
        XCTAssertTrue(settings.isPaused)
        XCTAssertNotNil(settings.pauseUntil)

        settings.resume()
        XCTAssertFalse(settings.isPaused)
        XCTAssertNil(settings.pauseUntil)
    }

    func testBreakManagerDurationFormatting() {
        let manager = BreakManager.shared
        XCTAssertEqual(manager.formattedDuration(20), "20s")
        XCTAssertEqual(manager.formattedDuration(65), "01:05")
        XCTAssertEqual(manager.formattedDuration(120), "02:00")
    }

    func testBreakManagerBreakCycle() {
        let manager = BreakManager.shared
        manager.resetTimers()

        // Start break
        manager.startBreak(forcedDuration: 10)
        XCTAssertTrue(manager.isBreakActive)
        XCTAssertEqual(manager.breakRemainingSeconds, 10)

        // Snooze break
        manager.snoozeBreak(minutes: 5)
        XCTAssertFalse(manager.isBreakActive)
        XCTAssertEqual(manager.timeUntilBreak, 300)

        // Start and complete break
        manager.startBreak(forcedDuration: 5)
        manager.completeBreak()
        XCTAssertFalse(manager.isBreakActive)
        XCTAssertEqual(manager.timeUntilBreak, AppSettings.shared.breakIntervalMinutes * 60)
    }

    func testBlinkTrigger() {
        let manager = BreakManager.shared
        var blinkNotified = false
        manager.onBlinkTriggered = {
            blinkNotified = true
        }

        manager.triggerBlink()
        XCTAssertTrue(blinkNotified)
        XCTAssertEqual(manager.timeUntilBlink, AppSettings.shared.blinkIntervalMinutes * 60)
    }
}
