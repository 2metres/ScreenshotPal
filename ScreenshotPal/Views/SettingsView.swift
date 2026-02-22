import AppKit
import Sparkle
import SwiftUI

struct SettingsView: View {
    @ObservedObject var directoryManager: ScreenshotDirectoryManager
    var updater: SPUUpdater
    var onDirectoryChanged: (URL) -> Void
    var onTrashAll: () -> Void
    @State private var showTrashConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Screenshot folder section
            VStack(alignment: .leading, spacing: 8) {
                Text("Screenshot Folder")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(directoryManager.displayPath)
                    .font(.system(.caption, design: .monospaced))
                    .padding(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(4)

                if directoryManager.source == .osDefault {
                    Text("Detected from macOS settings")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Button("Choose Folder...") {
                        chooseFolder()
                    }

                    if directoryManager.source == .custom {
                        Button("Reset to Default") {
                            directoryManager.resetToOSDefault()
                            onDirectoryChanged(directoryManager.directoryURL)
                        }
                    }
                }
            }

            Divider()

            // Grid size section
            VStack(alignment: .leading, spacing: 8) {
                Text("Grid Size")
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack {
                    Text("\(directoryManager.gridColumns)")
                        .font(.system(.caption, design: .monospaced))
                        .frame(width: 16)
                    Slider(value: Binding(
                        get: { Double(directoryManager.gridColumns) },
                        set: { directoryManager.gridColumns = Int($0) }
                    ), in: 1 ... 4, step: 1)
                }

                Text("\(directoryManager.gridColumns) column\(directoryManager.gridColumns == 1 ? "" : "s")")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Divider()

            // Updates section
            CheckForUpdatesView(updater: updater)

            Divider()

            // Clear all section
            Button(role: .destructive) {
                showTrashConfirmation = true
            } label: {
                Label("Move All to Trash", systemImage: "trash")
            }
            .alert("Move All to Trash?", isPresented: $showTrashConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Move to Trash", role: .destructive) {
                    onTrashAll()
                }
            } message: {
                Text("All screenshots and recordings in this folder will be moved to the Trash.")
            }
        }
        .padding()
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.level = .floating
        panel.prompt = "Choose"

        if panel.runModal() == .OK, let url = panel.url {
            directoryManager.setCustomDirectory(url)
            onDirectoryChanged(url)
        }
    }
}
