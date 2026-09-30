import AppKit
import SwiftUI

@MainActor
final class StatusItemController: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var hoverTimer: Timer?
    private var tooltipPanel: NSPanel?
    private var tooltipLabel: NSTextField?
    private var exactTotal = DurationFormat.string(from: 0)

    func applicationDidFinishLaunching(_ notification: Notification) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
            button.target = self
            button.action = #selector(toggleWindow)
        }
        statusItem = item
        update(total: 0)
        let timer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.updateHover()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        hoverTimer = timer
    }

    func update(total: TimeInterval) {
        guard let button = statusItem?.button else { return }
        exactTotal = DurationFormat.string(from: total)
        button.toolTip = exactTotal
        if let short = DurationFormat.menuBarString(from: total) {
            button.image = nil
            button.title = short
            button.setAccessibilityLabel("Total tracked time \(exactTotal)")
        } else {
            button.title = ""
            let image = NSImage(systemSymbolName: "timer", accessibilityDescription: "Tiempo")
            image?.isTemplate = true
            button.image = image
            button.setAccessibilityLabel("Tiempo")
        }
        if tooltipPanel?.isVisible == true {
            showTimeTooltip()
        }
    }

    private func updateHover() {
        guard let button = statusItem?.button, let buttonWindow = button.window else { return }
        let buttonRect = buttonWindow.convertToScreen(button.convert(button.bounds, to: nil))
        if buttonRect.contains(NSEvent.mouseLocation) {
            showTimeTooltip()
        } else if tooltipPanel?.isVisible == true {
            tooltipPanel?.orderOut(nil)
        }
    }

    private func showTimeTooltip() {
        guard let button = statusItem?.button, let buttonWindow = button.window else { return }
        let panel = tooltipPanel ?? makeTooltipPanel()
        let label = tooltipLabel
        label?.stringValue = exactTotal
        let labelSize = label?.fittingSize ?? .zero
        let size = NSSize(width: labelSize.width + 16, height: labelSize.height + 8)
        label?.frame = NSRect(x: 8, y: 4, width: labelSize.width, height: labelSize.height)
        let buttonRect = buttonWindow.convertToScreen(button.convert(button.bounds, to: nil))
        var origin = NSPoint(x: buttonRect.midX - size.width / 2, y: buttonRect.minY - size.height - 2)
        if let visible = buttonWindow.screen?.visibleFrame {
            origin.x = min(max(origin.x, visible.minX + 4), visible.maxX - size.width - 4)
        }
        panel.setFrame(NSRect(origin: origin, size: size), display: true)
        panel.appearance = button.effectiveAppearance
        panel.orderFrontRegardless()
    }

    private func makeTooltipPanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .popUpMenu
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .transient, .ignoresCycle]

        let background = NSVisualEffectView()
        background.material = .popover
        background.blendingMode = .behindWindow
        background.state = .active
        background.wantsLayer = true
        background.layer?.cornerRadius = 6
        background.layer?.masksToBounds = true
        panel.contentView = background

        let label = NSTextField(labelWithString: exactTotal)
        label.font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .regular)
        label.textColor = .labelColor
        background.addSubview(label)
        tooltipPanel = panel
        tooltipLabel = label
        return panel
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        guard !flag else { return true }
        showWindow()
        return false
    }

    @objc private func toggleWindow() {
        tooltipPanel?.orderOut(nil)
        if let window = appWindows().first(where: \.isVisible) {
            window.orderOut(nil)
            return
        }
        showWindow()
    }

    private func appWindows() -> [NSWindow] {
        NSApp.windows.filter { $0.level == .normal }
    }

    private func showWindow() {
        let windows = appWindows()
        guard let window = windows.first(where: { !$0.isVisible }) ?? windows.first else { return }
        NSRunningApplication.current.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
        window.makeKeyAndOrderFront(nil)
    }
}

struct HideOnClose: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        NSView(frame: .zero)
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            guard let window = nsView.window else { return }
            context.coordinator.attach(to: window)
        }
    }

    func makeCoordinator() -> WindowCloseProxy {
        WindowCloseProxy()
    }
}

final class WindowCloseProxy: NSObject, NSWindowDelegate {
    private weak var original: NSWindowDelegate?

    func attach(to window: NSWindow) {
        guard window.delegate !== self else { return }
        original = window.delegate
        window.delegate = self
        window.isReleasedWhenClosed = false
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false
    }

    override func responds(to aSelector: Selector!) -> Bool {
        if super.responds(to: aSelector) { return true }
        guard let aSelector else { return false }
        return original?.responds(to: aSelector) ?? false
    }

    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        original
    }
}
