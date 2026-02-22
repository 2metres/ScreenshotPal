import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ScreenshotThumbnail: View {
    let screenshot: Screenshot
    let thumbnail: NSImage?
    let isSelected: Bool
    let columnCount: Int
    let onSelect: () -> Void
    @State private var isHovering = false

    private var tileAspectRatio: CGFloat {
        columnCount == 1 ? 5.0 / 4.0 : 1.0
    }

    var body: some View {
        Group {
            Color.clear
                .aspectRatio(tileAspectRatio, contentMode: .fit)
                .overlay(
                    Group {
                        if let image = thumbnail {
                            Image(nsImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            Color.gray.opacity(0.2)
                                .overlay(ProgressView().scaleEffect(0.5))
                        }
                    }
                )
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .overlay(
            Group {
                if screenshot.isVideo {
                    GeometryReader { geo in
                        let circleSize = geo.size.width * 0.35
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: circleSize, height: circleSize)
                            Image(systemName: "play.fill")
                                .font(.system(size: circleSize * 0.38))
                                .foregroundStyle(.white)
                                .offset(x: circleSize * 0.03)
                        }
                        .shadow(radius: 3)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            },
            alignment: .center
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected || isHovering ? Color.accentColor : Color.clear, lineWidth: 4)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovering = hovering
        }
        .onDrag {
            let provider = NSItemProvider()
            let url = screenshot.url
            let type = UTType(filenameExtension: url.pathExtension) ?? .data

            provider.suggestedName = url.lastPathComponent

            // Provide the actual file so drop targets receive file data (like Finder)
            provider.registerFileRepresentation(
                forTypeIdentifier: type.identifier,
                fileOptions: [],
                visibility: .all
            ) { completion in
                completion(url, false, nil)
                return nil
            }

            // Fallback: provide the file URL for drop targets that accept URLs
            provider.registerObject(url as NSURL, visibility: .all)

            return provider
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
                        NSWorkspace.shared.open(
                            [screenshot.url],
                            withApplicationAt: appURL,
                            configuration: NSWorkspace.OpenConfiguration()
                        )
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
