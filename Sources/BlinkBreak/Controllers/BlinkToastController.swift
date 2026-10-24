import AppKit
import SwiftUI

@MainActor
public final class BlinkToastController {
    public static let shared = BlinkToastController()

    private var toastPanel: NSPanel?
    private var isAnimatingOut = false

    private init() {}

    public func show() {
        BlinkToastState.shared.stop()
        isAnimatingOut = false

        let capsuleHeight: CGFloat = 36
        let panelWidth: CGFloat = 240
        let panelHeight: CGFloat = 60

        guard let screen = NSScreen.main else { return }

        // The MacBook hardware notch is centered at physical screen.frame.midX
        let notchCenterX = screen.frame.midX
        let targetX = notchCenterX - (panelWidth / 2)

        // Notch bottom edge in macOS screen coordinates
        let notchBottomY: CGFloat
        if screen.safeAreaInsets.top > 0 {
            notchBottomY = screen.frame.maxY - screen.safeAreaInsets.top
        } else {
            notchBottomY = screen.visibleFrame.maxY
        }

        // Float 8pt directly below the notch
        let capsuleGap: CGFloat = 8.0
        let capsuleTopY = notchBottomY - capsuleGap
        let verticalMargin = (panelHeight - capsuleHeight) / 2
        let targetY = capsuleTopY - capsuleHeight - verticalMargin
        let startY = notchBottomY + 12

        let panel: NSPanel
        if let existing = toastPanel {
            panel = existing
        } else {
            panel = NSPanel(
                contentRect: NSRect(x: targetX, y: startY, width: panelWidth, height: panelHeight),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.level = .statusBar
            panel.hasShadow = false
            panel.ignoresMouseEvents = false
            panel.acceptsMouseMovedEvents = true
            panel.collectionBehavior = [.canJoinAllSpaces, .transient, .fullScreenAuxiliary]
            toastPanel = panel
        }

        let contentView = BlinkToastView { [weak self] in
            self?.hide()
        }

        panel.appearance = NSApp.effectiveAppearance

        let hostingView = NSHostingView(rootView: contentView)
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        hostingView.appearance = NSApp.effectiveAppearance
        panel.contentView = hostingView

        panel.setFrame(NSRect(x: targetX, y: startY, width: panelWidth, height: panelHeight), display: true)
        panel.alphaValue = 0.0
        panel.orderFrontRegardless()

        // Apple fluid spring drop-in
        let springTiming = CAMediaTimingFunction(controlPoints: 0.25, 1.15, 0.45, 1.0)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.32
            context.timingFunction = springTiming
            panel.animator().setFrame(NSRect(x: targetX, y: targetY, width: panelWidth, height: panelHeight), display: true)
            panel.animator().alphaValue = 1.0
        }

        BlinkToastState.shared.start(duration: 5.0) { [weak self] in
            self?.hide()
        }
    }

    public func hide() {
        guard !isAnimatingOut, let panel = toastPanel else { return }
        isAnimatingOut = true
        BlinkToastState.shared.stop()

        guard let screen = NSScreen.main else {
            panel.orderOut(nil)
            toastPanel = nil
            isAnimatingOut = false
            return
        }

        let panelWidth: CGFloat = 240
        let panelHeight: CGFloat = 60
        let notchCenterX = screen.frame.midX
        let targetX = notchCenterX - (panelWidth / 2)

        let notchBottomY: CGFloat
        if screen.safeAreaInsets.top > 0 {
            notchBottomY = screen.frame.maxY - screen.safeAreaInsets.top
        } else {
            notchBottomY = screen.visibleFrame.maxY
        }
        let endY = notchBottomY + 12

        let exitTiming = CAMediaTimingFunction(name: .easeIn)
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.22
            context.timingFunction = exitTiming
            panel.animator().setFrame(NSRect(x: targetX, y: endY, width: panelWidth, height: panelHeight), display: true)
            panel.animator().alphaValue = 0.0
        }, completionHandler: { [weak self] in
            Task { @MainActor in
                panel.orderOut(nil)
                self?.toastPanel = nil
                self?.isAnimatingOut = false
            }
        })
    }
}
