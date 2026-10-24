import AppKit
import SwiftUI

@MainActor
public final class BlinkScreenEffectController {
    public static let shared = BlinkScreenEffectController()

    private var effectPanels: [NSPanel] = []

    private init() {}

    public func showEffect(onPillTrigger: @escaping @MainActor () -> Void) {
        hide()

        guard let screen = NSScreen.main else {
            onPillTrigger()
            return
        }

        let panel = NSPanel(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .floating
        panel.hasShadow = false
        panel.ignoresMouseEvents = true // Zero interference with user clicks and keyboard typing
        panel.acceptsMouseMovedEvents = false
        panel.collectionBehavior = [.canJoinAllSpaces, .transient, .fullScreenAuxiliary]

        let contentView = BlinkScreenEffectView(screenFrame: screen.frame)
        panel.appearance = NSApp.effectiveAppearance

        let hostingView = NSHostingView(rootView: contentView)
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        hostingView.appearance = NSApp.effectiveAppearance
        panel.contentView = hostingView

        panel.orderFrontRegardless()
        effectPanels.append(panel)

        BlinkScreenEffectState.shared.start(
            duration: 0.82,
            onPillTrigger: {
                onPillTrigger()
            },
            onComplete: { [weak self] in
                self?.hide()
            }
        )
    }

    public func hide() {
        BlinkScreenEffectState.shared.reset()
        for panel in effectPanels {
            panel.orderOut(nil)
        }
        effectPanels.removeAll()
    }
}
