import SwiftUI
import Quartz

class QuickLookCoordinator {
    private var panel: NSPanel?
    private var previewView: QLPreviewView?

    private var appDelegate: AppDelegate? {
        NSApp.delegate as? AppDelegate
    }

    var isOpen: Bool {
        panel?.isVisible ?? false
    }

    func open(url: URL) {
        if let panel = panel {
            previewView?.previewItem = url as NSURL
            panel.orderFront(nil)
        } else {
            let preview = QLPreviewView(frame: NSRect(x: 0, y: 0, width: 600, height: 500))!
            preview.previewItem = url as NSURL
            self.previewView = preview

            let window = NonActivatingPanel(
                contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
                styleMask: [.titled, .closable, .resizable, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            window.contentView = preview
            window.title = "Preview"
            window.center()
            window.isFloatingPanel = true
            window.hidesOnDeactivate = false
            window.isReleasedWhenClosed = false
            self.panel = window
            window.orderFront(nil)
        }
        appDelegate?.preventClose = true
    }

    func close() {
        panel?.orderOut(nil)
        appDelegate?.preventClose = false
    }

    func updatePreview(url: URL) {
        previewView?.previewItem = url as NSURL
    }
}

class NonActivatingPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

struct MenubarPopover: View {
    @StateObject private var directoryManager = ScreenshotDirectoryManager()
    @StateObject private var store = ScreenshotStore()
    @State private var showSettings = false
    @State private var selectedID: UUID?
    @State private var keyMonitor: Any?

    private let quickLook = QuickLookCoordinator()

    var body: some View {
        VStack(spacing: 0) {
            if showSettings {
                // Settings pane
                HStack {
                    Button(action: { showSettings = false }) {
                        Image(systemName: "chevron.left")
                    }
                    .buttonStyle(.borderless)
                    Text("Settings")
                        .font(.headline)
                    Spacer()
                }
                .padding()

                Divider()

                SettingsView(directoryManager: directoryManager) { newURL in
                    store.updateDirectory(newURL)
                }

                Spacer()
            } else {
                // Main pane
                HStack {
                    Text("Screenshots")
                        .font(.headline)
                    Spacer()
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape")
                    }
                    .buttonStyle(.borderless)

                    Button(action: { store.loadScreenshots() }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.borderless)
                }
                .padding()

                Divider()

                if store.screenshots.isEmpty {
                    VStack {
                        Spacer()
                        Text("No screenshots found")
                            .foregroundColor(.secondary)
                        Text("Take a screenshot with \u{2318}\u{21E7}3 or \u{2318}\u{21E7}4")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        ScreenshotGrid(screenshots: store.screenshots, selectedID: $selectedID)
                            .padding()
                    }
                }
            }
        }
        .frame(width: 320, height: 400)
        .onReceive(NotificationCenter.default.publisher(for: .popoverDidClose)) { _ in
            showSettings = false
            selectedID = nil
            if quickLook.isOpen { quickLook.close() }
        }
        .onAppear {
            keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                // Spacebar: toggle QuickLook
                if event.keyCode == 49 {
                    if quickLook.isOpen {
                        quickLook.close()
                    } else if let id = selectedID,
                              let screenshot = store.screenshots.first(where: { $0.id == id }) {
                        quickLook.open(url: screenshot.url)
                    }
                    return nil
                }

                // Arrow keys: navigate selection
                let columns = 3
                let delta: Int? = {
                    switch event.keyCode {
                    case 123: return -1         // left
                    case 124: return 1          // right
                    case 125: return columns    // down
                    case 126: return -columns   // up
                    default: return nil
                    }
                }()

                if let delta = delta, !store.screenshots.isEmpty {
                    let currentIndex = store.screenshots.firstIndex(where: { $0.id == selectedID }) ?? -1
                    let newIndex = max(0, min(store.screenshots.count - 1, currentIndex + delta))
                    selectedID = store.screenshots[newIndex].id
                    quickLook.updatePreview(url: store.screenshots[newIndex].url)
                    return nil
                }

                return event
            }
        }
        .onDisappear {
            if let monitor = keyMonitor {
                NSEvent.removeMonitor(monitor)
                keyMonitor = nil
            }
        }
    }
}
