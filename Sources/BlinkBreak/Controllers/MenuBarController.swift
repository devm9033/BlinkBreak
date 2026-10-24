import AppKit

@MainActor
public final class MenuBarController: NSObject, NSMenuDelegate {
    public static let shared = MenuBarController()

    private var statusItem: NSStatusItem?
    private let menu = NSMenu()
    private var isMenuOpen = false

    private var nextBreakMenuItem: NSMenuItem!
    private var nextBlinkMenuItem: NSMenuItem!
    private var pauseSubmenuItem: NSMenuItem!
    private var resumeMenuItem: NSMenuItem!

    private override init() {
        super.init()
    }

    public func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            if let image = NSImage(systemSymbolName: "eye", accessibilityDescription: "BlinkBreak") {
                image.isTemplate = true
                button.image = image
            } else {
                button.title = "👁"
            }
            button.toolTip = "BlinkBreak - Rest & Blink Reminders"
        }

        buildMenu()
        statusItem?.menu = menu
        menu.delegate = self

        // Wire manager callbacks
        let manager = BreakManager.shared
        manager.onBreakStarted = { _ in
            BreakOverlayController.shared.show()
        }

        manager.onBreakEnded = {
            BreakOverlayController.shared.hide()
        }

        manager.onBlinkTriggered = {
            if AppSettings.shared.ambientGlowEnabled {
                BlinkScreenEffectController.shared.showEffect {
                    BlinkToastController.shared.show()
                }
            } else {
                BlinkToastController.shared.show()
            }
        }

        manager.onTick = { [weak self] in
            guard let self = self, self.isMenuOpen else { return }
            self.updateMenuTitles()
        }
    }

    private func buildMenu() {
        menu.removeAllItems()

        // Title
        let titleItem = NSMenuItem(title: "BlinkBreak", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)

        menu.addItem(NSMenuItem.separator())

        // Timer readouts
        nextBreakMenuItem = NSMenuItem(title: "Next Break: --:--", action: nil, keyEquivalent: "")
        nextBreakMenuItem.isEnabled = false
        menu.addItem(nextBreakMenuItem)

        nextBlinkMenuItem = NSMenuItem(title: "Next Blink: --:--", action: nil, keyEquivalent: "")
        nextBlinkMenuItem.isEnabled = false
        menu.addItem(nextBlinkMenuItem)

        menu.addItem(NSMenuItem.separator())

        // Quick triggers
        let takeBreakItem = NSMenuItem(title: "Take Break Now", action: #selector(takeBreakNow), keyEquivalent: "b")
        takeBreakItem.target = self
        menu.addItem(takeBreakItem)

        let blinkNowItem = NSMenuItem(title: "Blink Reminder Now", action: #selector(blinkNow), keyEquivalent: "l")
        blinkNowItem.target = self
        menu.addItem(blinkNowItem)

        menu.addItem(NSMenuItem.separator())

        // Pause / Resume submenu
        pauseSubmenuItem = NSMenuItem(title: "Pause", action: nil, keyEquivalent: "")
        let pauseMenu = NSMenu(title: "Pause")

        let pause15 = NSMenuItem(title: "For 15 minutes", action: #selector(pause15m), keyEquivalent: "")
        pause15.target = self
        pauseMenu.addItem(pause15)

        let pause30 = NSMenuItem(title: "For 30 minutes", action: #selector(pause30m), keyEquivalent: "")
        pause30.target = self
        pauseMenu.addItem(pause30)

        let pause60 = NSMenuItem(title: "For 1 hour", action: #selector(pause1h), keyEquivalent: "")
        pause60.target = self
        pauseMenu.addItem(pause60)

        let pauseDay = NSMenuItem(title: "Until tomorrow", action: #selector(pauseTomorrow), keyEquivalent: "")
        pauseDay.target = self
        pauseMenu.addItem(pauseDay)

        pauseSubmenuItem.submenu = pauseMenu
        menu.addItem(pauseSubmenuItem)

        resumeMenuItem = NSMenuItem(title: "Resume Reminders", action: #selector(resumeTimers), keyEquivalent: "")
        resumeMenuItem.target = self
        resumeMenuItem.isHidden = true
        menu.addItem(resumeMenuItem)

        menu.addItem(NSMenuItem.separator())

        // Preferences
        let prefsItem = NSMenuItem(title: "Preferences...", action: #selector(openPreferences), keyEquivalent: ",")
        prefsItem.target = self
        menu.addItem(prefsItem)

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(title: "Quit BlinkBreak", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        updateMenuTitles()
    }

    public func menuWillOpen(_ menu: NSMenu) {
        isMenuOpen = true
        updateMenuTitles()
    }

    public func menuDidClose(_ menu: NSMenu) {
        isMenuOpen = false
    }

    private func updateMenuTitles() {
        let manager = BreakManager.shared
        let settings = AppSettings.shared

        if settings.isPaused {
            if let until = settings.pauseUntil {
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                nextBreakMenuItem.title = "Paused until \(formatter.string(from: until))"
            } else {
                nextBreakMenuItem.title = "Paused"
            }
            nextBlinkMenuItem.title = "Timers suspended"
            resumeMenuItem.isHidden = false
            pauseSubmenuItem.isHidden = true
        } else if manager.isBreakPausedDueToVideo || manager.isBlinkPausedDueToVideo {
            let procSuffix = manager.videoProcessName.map { " (\($0))" } ?? ""
            if manager.isBreakPausedDueToVideo {
                nextBreakMenuItem.title = "Next Break: Paused (Video Playing\(procSuffix))"
            } else {
                nextBreakMenuItem.title = "Next Break: \(manager.formattedDuration(manager.timeUntilBreak))"
            }

            if manager.isBlinkPausedDueToVideo {
                nextBlinkMenuItem.title = "Next Blink: Paused (Video Playing\(procSuffix))"
            } else {
                nextBlinkMenuItem.title = "Next Blink: \(manager.formattedDuration(manager.timeUntilBlink))"
            }
            resumeMenuItem.isHidden = true
            pauseSubmenuItem.isHidden = false
        } else {
            nextBreakMenuItem.title = "Next Break: \(manager.formattedDuration(manager.timeUntilBreak))"
            nextBlinkMenuItem.title = "Next Blink: \(manager.formattedDuration(manager.timeUntilBlink))"
            resumeMenuItem.isHidden = true
            pauseSubmenuItem.isHidden = false
        }
    }

    @objc private func takeBreakNow() {
        BreakManager.shared.startBreak()
    }

    @objc private func blinkNow() {
        BreakManager.shared.triggerBlink()
    }

    @objc private func pause15m() {
        AppSettings.shared.pause(minutes: 15)
        updateMenuTitles()
    }

    @objc private func pause30m() {
        AppSettings.shared.pause(minutes: 30)
        updateMenuTitles()
    }

    @objc private func pause1h() {
        AppSettings.shared.pause(minutes: 60)
        updateMenuTitles()
    }

    @objc private func pauseTomorrow() {
        AppSettings.shared.pauseUntilTomorrow()
        updateMenuTitles()
    }

    @objc private func resumeTimers() {
        AppSettings.shared.resume()
        updateMenuTitles()
    }

    @objc private func openPreferences() {
        SettingsWindowController.shared.show()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
