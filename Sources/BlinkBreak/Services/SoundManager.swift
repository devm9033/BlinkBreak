import AppKit

@MainActor
public final class SoundManager {
    public static let shared = SoundManager()

    public static let availableBlinkSounds: [String] = [
        "Pop",
        "Bottle",
        "Purr",
        "Blow",
        "Glass",
        "Tink",
        "None"
    ]

    public static let availableBreakSounds: [String] = [
        "Glass",
        "Ping",
        "Pop",
        "Submarine",
        "Hero",
        "Bottle",
        "None"
    ]

    private init() {}

    public func playSound(name: String) {
        guard name != "None" else { return }
        if let sound = NSSound(named: name) {
            sound.stop()
            sound.play()
        }
    }

    public func playBreakStart() {
        guard AppSettings.shared.soundEnabled else { return }
        playSound(name: AppSettings.shared.breakSoundName)
    }

    public func playBreakEnd() {
        guard AppSettings.shared.soundEnabled else { return }
        // Play Ping or selected break sound
        if AppSettings.shared.breakSoundName != "None" {
            if let sound = NSSound(named: "Ping") {
                sound.play()
            }
        }
    }

    public func playBlinkReminder() {
        guard AppSettings.shared.soundEnabled else { return }
        playSound(name: AppSettings.shared.blinkSoundName)
    }
}
