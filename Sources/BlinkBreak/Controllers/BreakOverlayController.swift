import AppKit
import SwiftUI

@MainActor
final class BreakOverlayWindow: NSWindow {
    var onEscapePressed: (@MainActor () -> Void)?

    override var canBecomeKey: Bool {
        return true
    }

    override var canBecomeMain: Bool {
        return true
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // ESC key
            onEscapePressed?()
        } else {
            super.keyDown(with: event)
        }
    }
}

@MainActor
public final class BreakOverlayController {
    public static let shared = BreakOverlayController()

    private var windows: [NSWindow] = []

    private init() {}

    public func show() {
        hide()

        BreakOverlayViewState.shared.reset()

        let screens = NSScreen.screens
        guard !screens.isEmpty else { return }

        for screen in screens {
            let window = BreakOverlayWindow(
                contentRect: screen.frame,
                styleMask: [.borderless, .fullSizeContentView],
                backing: .buffered,
                defer: false,
                screen: screen
            )

            window.level = .floating
            window.isOpaque = false
            window.backgroundColor = .clear
            window.hasShadow = false
            window.ignoresMouseEvents = false
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

            let contentView = BreakOverlayView(
                onSkip: { [weak self] in
                    BreakManager.shared.skipBreak()
                    self?.hide()
                },
                onSnooze: { [weak self] in
                    BreakManager.shared.snoozeBreak(minutes: 5)
                    self?.hide()
                }
            )

            window.onEscapePressed = { [weak self] in
                BreakManager.shared.skipBreak()
                self?.hide()
            }

            let hostingView = NSHostingView(rootView: contentView)
            hostingView.wantsLayer = true
            hostingView.layer?.backgroundColor = NSColor.clear.cgColor
            window.contentView = hostingView

            window.alphaValue = 0.0
            window.makeKeyAndOrderFront(nil)

            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.22
                window.animator().alphaValue = 1.0
            }

            windows.append(window)
        }

        NSApp.activate(ignoringOtherApps: true)
    }

    public func hide() {
        guard !windows.isEmpty else { return }
        let currentWindows = windows
        windows = []

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.20
            for window in currentWindows {
                window.animator().alphaValue = 0.0
            }
        }, completionHandler: {
            Task { @MainActor in
                for window in currentWindows {
                    window.orderOut(nil)
                }
                BreakOverlayViewState.shared.reset()
            }
        })
    }
}
