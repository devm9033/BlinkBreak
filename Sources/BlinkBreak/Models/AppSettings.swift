import Foundation
import Combine

@MainActor
public final class AppSettings: ObservableObject {
    public static let shared = AppSettings()

    private enum Keys {
        static let isBreakEnabled = "isBreakEnabled"
        static let isBlinkEnabled = "isBlinkEnabled"
        static let breakIntervalMinutes = "breakIntervalMinutes"
        static let breakDurationSeconds = "breakDurationSeconds"
        static let blinkIntervalMinutes = "blinkIntervalMinutes"
        static let blinkDurationSeconds = "blinkDurationSeconds"
        static let soundEnabled = "soundEnabled"
        static let blinkSoundName = "blinkSoundName"
        static let breakSoundName = "breakSoundName"
        static let pauseBreaksDuringVideo = "pauseBreaksDuringVideo"
        static let pauseBlinksDuringVideo = "pauseBlinksDuringVideo"
        static let ambientGlowEnabled = "ambientGlowEnabled"
    }

    @Published public var isBreakEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isBreakEnabled, forKey: Keys.isBreakEnabled)
            onSettingsChanged?()
        }
    }

    @Published public var isBlinkEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isBlinkEnabled, forKey: Keys.isBlinkEnabled)
            onSettingsChanged?()
        }
    }

    @Published public var breakIntervalMinutes: Int {
        didSet {
            UserDefaults.standard.set(breakIntervalMinutes, forKey: Keys.breakIntervalMinutes)
            onSettingsChanged?()
        }
    }

    @Published public var breakDurationSeconds: Int {
        didSet {
            UserDefaults.standard.set(breakDurationSeconds, forKey: Keys.breakDurationSeconds)
            onSettingsChanged?()
        }
    }

    @Published public var blinkIntervalMinutes: Int {
        didSet {
            UserDefaults.standard.set(blinkIntervalMinutes, forKey: Keys.blinkIntervalMinutes)
            onSettingsChanged?()
        }
    }

    @Published public var blinkDurationSeconds: Int {
        didSet {
            UserDefaults.standard.set(blinkDurationSeconds, forKey: Keys.blinkDurationSeconds)
            onSettingsChanged?()
        }
    }

    @Published public var soundEnabled: Bool {
        didSet {
            UserDefaults.standard.set(soundEnabled, forKey: Keys.soundEnabled)
        }
    }

    @Published public var blinkSoundName: String {
        didSet {
            UserDefaults.standard.set(blinkSoundName, forKey: Keys.blinkSoundName)
        }
    }

    @Published public var breakSoundName: String {
        didSet {
            UserDefaults.standard.set(breakSoundName, forKey: Keys.breakSoundName)
        }
    }

    @Published public var pauseBreaksDuringVideo: Bool {
        didSet {
            UserDefaults.standard.set(pauseBreaksDuringVideo, forKey: Keys.pauseBreaksDuringVideo)
            onSettingsChanged?()
        }
    }

    @Published public var pauseBlinksDuringVideo: Bool {
        didSet {
            UserDefaults.standard.set(pauseBlinksDuringVideo, forKey: Keys.pauseBlinksDuringVideo)
            onSettingsChanged?()
        }
    }

    @Published public var ambientGlowEnabled: Bool {
        didSet {
            UserDefaults.standard.set(ambientGlowEnabled, forKey: Keys.ambientGlowEnabled)
            onSettingsChanged?()
        }
    }

    @Published public var isPaused: Bool = false
    @Published public var pauseUntil: Date? = nil

    public var onSettingsChanged: (@MainActor () -> Void)?

    private init() {
        let defaults = UserDefaults.standard
        
        defaults.register(defaults: [
            Keys.isBreakEnabled: true,
            Keys.isBlinkEnabled: true,
            Keys.breakIntervalMinutes: 20,
            Keys.breakDurationSeconds: 20,
            Keys.blinkIntervalMinutes: 5,
            Keys.blinkDurationSeconds: 5,
            Keys.soundEnabled: true,
            Keys.blinkSoundName: "Pop",
            Keys.breakSoundName: "Glass",
            Keys.pauseBreaksDuringVideo: true,
            Keys.pauseBlinksDuringVideo: false,
            Keys.ambientGlowEnabled: true
        ])

        if defaults.object(forKey: Keys.isBreakEnabled) != nil {
            self.isBreakEnabled = defaults.bool(forKey: Keys.isBreakEnabled)
        } else {
            self.isBreakEnabled = true
        }

        if defaults.object(forKey: Keys.isBlinkEnabled) != nil {
            self.isBlinkEnabled = defaults.bool(forKey: Keys.isBlinkEnabled)
        } else {
            self.isBlinkEnabled = true
        }

        let savedBreakInterval = defaults.integer(forKey: Keys.breakIntervalMinutes)
        let savedBreakDuration = defaults.integer(forKey: Keys.breakDurationSeconds)
        let savedBlinkInterval = defaults.integer(forKey: Keys.blinkIntervalMinutes)
        let savedBlinkDuration = defaults.integer(forKey: Keys.blinkDurationSeconds)

        self.breakIntervalMinutes = savedBreakInterval > 0 ? savedBreakInterval : 20
        self.breakDurationSeconds = savedBreakDuration > 0 ? savedBreakDuration : 20
        self.blinkIntervalMinutes = savedBlinkInterval > 0 ? savedBlinkInterval : 5
        self.blinkDurationSeconds = savedBlinkDuration > 0 ? savedBlinkDuration : 5
        self.soundEnabled = defaults.bool(forKey: Keys.soundEnabled)
        self.blinkSoundName = defaults.string(forKey: Keys.blinkSoundName) ?? "Pop"
        self.breakSoundName = defaults.string(forKey: Keys.breakSoundName) ?? "Glass"
        if defaults.object(forKey: Keys.pauseBreaksDuringVideo) != nil {
            self.pauseBreaksDuringVideo = defaults.bool(forKey: Keys.pauseBreaksDuringVideo)
        } else {
            self.pauseBreaksDuringVideo = true
        }
        if defaults.object(forKey: Keys.pauseBlinksDuringVideo) != nil {
            self.pauseBlinksDuringVideo = defaults.bool(forKey: Keys.pauseBlinksDuringVideo)
        } else {
            self.pauseBlinksDuringVideo = false
        }
        if defaults.object(forKey: Keys.ambientGlowEnabled) != nil {
            self.ambientGlowEnabled = defaults.bool(forKey: Keys.ambientGlowEnabled)
        } else {
            self.ambientGlowEnabled = true
        }
    }

    public func pause(minutes: Int) {
        isPaused = true
        pauseUntil = Date().addingTimeInterval(TimeInterval(minutes * 60))
    }

    public func pauseUntilTomorrow() {
        isPaused = true
        let calendar = Calendar.current
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()),
           let tomorrowMorning = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow) {
            pauseUntil = tomorrowMorning
        } else {
            pauseUntil = Date().addingTimeInterval(86400)
        }
    }

    public func resume() {
        isPaused = false
        pauseUntil = nil
    }

    public func checkPauseStatus() {
        if isPaused, let until = pauseUntil {
            if Date() >= until {
                resume()
            }
        }
    }
}
