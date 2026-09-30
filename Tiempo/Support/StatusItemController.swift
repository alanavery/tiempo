import AppKit
import SwiftUI

final class StatusItemController: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
            button.target = self
            button.action = #selector(toggleWindow)
        }
        statusItem = item
        update(total: 0)
    }

    func update(total: TimeInterval) {
        guard let button = statusItem?.button else { return }
        let exact = DurationFormat.string(from: total)
        button.toolTip = exact
        if let short = DurationFormat.menuBarString(from: total) {
            button.image = nil
            button.title = short
            button.setAccessibilityLabel("Total tracked time \(exact)")
        } else {
            button.title = ""
            let image = NSImage(systemSymbolName: "timer", accessibilityDescription: "Tiempo")
            image?.isTemplate = true
            button.image = image
            button.setAccessibilityLabel("Tiempo")
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        guard !flag else { return true }
        showWindow()
        return false
    }

    @objc private func toggleWindow() {
        if hideIfFront() { return }
        showWindow()
    }

    private func appWindows() -> [NSWindow] {
        NSApp.windows.filter { $0.level == .normal }
    }

    @discardableResult
    private func hideIfFront() -> Bool {
        guard NSApp.isActive,
              let window = appWindows().first(where: { $0.isVisible && ($0.isKeyWindow || $0.isMainWindow) })
        else { return false }
        window.orderOut(nil)
        return true
    }

    private func showWindow() {
        let windows = appWindows()
        guard let window = windows.first(where: { !$0.isVisible }) ?? windows.first else { return }
        window.makeKeyAndOrderFront(nil)
        NSApp.activate()
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
