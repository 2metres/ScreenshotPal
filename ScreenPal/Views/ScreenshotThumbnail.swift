import SwiftUI
import AppKit

struct ScreenshotThumbnail: View {
    let screenshot: Screenshot
    let isSelected: Bool
    let onSelect: () -> Void
    @State private var isHovering = false

    var body: some View {
        Group {
            if let image = screenshot.image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 90, height: 90)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 90, height: 90)
                    .overlay(ProgressView().scaleEffect(0.5))
            }
        }
        .overlay(
            Group {
                if screenshot.isVideo {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 32, height: 32)
                        Image(systemName: "play.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.white)
                            .offset(x: 1)
                    }
                    .shadow(radius: 3)
                }
            },
            alignment: .center
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor : (isHovering ? Color.accentColor.opacity(0.5) : Color.clear), lineWidth: 2)
        )
        .onHover { hovering in
            isHovering = hovering
        }
        .onDrag {
            NSItemProvider(object: screenshot.url as NSURL)
        }
        .onTapGesture(count: 2) {
            NSWorkspace.shared.open(screenshot.url)
        }
        .onTapGesture(count: 1) {
            onSelect()
        }
        .contextMenu {
            Button("Open") {
                NSWorkspace.shared.open(screenshot.url)
            }

            Menu("Open With") {
                let appURLs = NSWorkspace.shared.urlsForApplications(toOpen: screenshot.url)
                let defaultApp = NSWorkspace.shared.urlForApplication(toOpen: screenshot.url)

                ForEach(appURLs.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }), id: \.self) { appURL in
                    let appName = appURL.deletingPathExtension().lastPathComponent
                    Button {
                        NSWorkspace.shared.open([screenshot.url], withApplicationAt: appURL, configuration: NSWorkspace.OpenConfiguration())
                    } label: {
                        if appURL == defaultApp {
                            Text(appName) + Text(" (Default)")
                                .foregroundColor(.secondary)
                        } else {
                            Text(appName)
                        }
                    }
                }
            }

            Divider()

            Button("Show in Finder") {
                NSWorkspace.shared.activateFileViewerSelecting([screenshot.url])
            }

            Button("Copy") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.writeObjects([screenshot.url as NSURL])
            }

            Divider()

            Button("Move to Trash", role: .destructive) {
                try? FileManager.default.trashItem(at: screenshot.url, resultingItemURL: nil)
            }
        }
        .help(screenshot.filename)
    }
}
