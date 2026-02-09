import Cocoa
import SwiftUI

extension Notification.Name {
    static let popoverDidClose = Notification.Name("popoverDidClose")
    static let popoverDidOpen = Notification.Name("popoverDidOpen")
}

class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var statusMenu: NSMenu?
    var preventClose = false
    private var clickMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "photo.on.rectangle.angled.fill", accessibilityDescription: "Screenshots")
            button.action = #selector(togglePopover)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit ScreenPal", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem?.menu = nil
        self.statusMenu = menu

        popover = NSPopover()
        popover?.contentSize = NSSize(width: 320, height: 400)
        popover?.behavior = .applicationDefined
        popover?.delegate = self
        popover?.contentViewController = NSHostingController(rootView: MenubarPopover())
    }

    @objc func togglePopover() {
        guard let button = statusItem?.button else { return }
        let event = NSApp.currentEvent

        if event?.type == .rightMouseUp {
            closePopover()
            statusItem?.menu = statusMenu
            button.performClick(nil)
            statusItem?.menu = nil
            return
        }

        guard let popover = popover else { return }

        if popover.isShown {
            closePopover()
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
            startClickMonitor()
            NotificationCenter.default.post(name: .popoverDidOpen, object: nil)
        }
    }

    private func closePopover() {
        popover?.performClose(nil)
        stopClickMonitor()
    }

    private func startClickMonitor() {
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self else { return }

            // Don't close if click landed on any of our own windows
            let clickLocation = event.locationInWindow == .zero ? NSEvent.mouseLocation : event.locationInWindow
            let mouseLocation = NSEvent.mouseLocation
            for window in NSApp.windows where window.isVisible {
                if window.frame.contains(mouseLocation) {
                    return
                }
            }

            self.closePopover()
        }
    }

    private func stopClickMonitor() {
        if let monitor = clickMonitor {
            NSEvent.removeMonitor(monitor)
            clickMonitor = nil
        }
    }

    func popoverShouldClose(_ popover: NSPopover) -> Bool {
        !preventClose
    }

    func popoverDidClose(_ notification: Notification) {
        stopClickMonitor()
        NotificationCenter.default.post(name: .popoverDidClose, object: nil)
    }
}
