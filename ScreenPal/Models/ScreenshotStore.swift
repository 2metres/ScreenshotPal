import Foundation
import AppKit
import QuickLookThumbnailing
import Combine

class ScreenshotStore: ObservableObject {
    @Published var screenshots: [Screenshot] = []
    @Published var thumbnails: [URL: NSImage] = [:]
    @Published var selectedID: UUID?

    private var screenshotDirectory: URL
    private var fileWatcher: DispatchSourceFileSystemObject?

    init(directory: URL? = nil) {
        if let directory = directory {
            screenshotDirectory = directory
        } else {
            screenshotDirectory = ScreenshotDirectoryManager().directoryURL
        }
        loadScreenshots()
        startWatching()
    }

    func updateDirectory(_ newDirectory: URL) {
        stopWatching()
        screenshotDirectory = newDirectory
        thumbnails = [:]
        screenshots = []
        loadScreenshots()
        startWatching()
    }

    func loadScreenshots() {
        let fileManager = FileManager.default

        do {
            let files = try fileManager.contentsOfDirectory(
                at: screenshotDirectory,
                includingPropertiesForKeys: [.creationDateKey]
            )

            let supportedExtensions: Set<String> = ["png", "mov"]
            let loaded = files
                .filter { supportedExtensions.contains($0.pathExtension.lowercased()) &&
                    ($0.lastPathComponent.contains("Screenshot") || $0.lastPathComponent.contains("Screen Recording"))
                }
                .map { Screenshot(url: $0) }
                .sorted { $0.createdAt > $1.createdAt }
                .prefix(30)
                .map { $0 }

            screenshots = loaded

            // Generate thumbnails for any that aren't cached yet
            let uncached = loaded.filter { thumbnails[$0.url] == nil }
            if !uncached.isEmpty {
                generateThumbnails(for: uncached)
            }
        } catch {
            print("Error loading screenshots: \(error)")
        }
    }

    private func generateThumbnails(for items: [Screenshot]) {
        let scale = NSScreen.main?.backingScaleFactor ?? 2.0
        let size = CGSize(width: 180, height: 180)

        for screenshot in items {
            let request = QLThumbnailGenerator.Request(
                fileAt: screenshot.url,
                size: size,
                scale: scale,
                representationTypes: .thumbnail
            )

            QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { [weak self] representation, _ in
                guard let representation = representation else { return }
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.thumbnails[screenshot.url] = representation.nsImage
                }
            }
        }
    }

    private func startWatching() {
        let fd = open(screenshotDirectory.path, O_EVTONLY)
        guard fd != -1 else { return }

        fileWatcher = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fd, eventMask: .write, queue: .main)

        fileWatcher?.setEventHandler { [weak self] in
            self?.loadScreenshots()
        }

        fileWatcher?.setCancelHandler {
            close(fd)
        }

        fileWatcher?.resume()
    }

    private func stopWatching() {
        fileWatcher?.cancel()
        fileWatcher = nil
    }

    func trashAll() {
        let fileManager = FileManager.default
        for screenshot in screenshots {
            do {
                try fileManager.trashItem(at: screenshot.url, resultingItemURL: nil)
            } catch {
                print("Error trashing \(screenshot.filename): \(error)")
            }
        }
    }

    deinit {
        stopWatching()
    }
}
