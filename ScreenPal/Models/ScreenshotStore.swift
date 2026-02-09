import Foundation
import AppKit
import AVFoundation
import Combine

class ScreenshotStore: ObservableObject {
    @Published var screenshots: [Screenshot] = []
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
        screenshots = []
        loadScreenshots()
        startWatching()
    }

    func loadScreenshots() {
        let fileManager = FileManager.default

        do {
            let files = try fileManager.contentsOfDirectory(at: screenshotDirectory, includingPropertiesForKeys: [.creationDateKey])

            let supportedExtensions: Set<String> = ["png", "mov"]
            var loaded = files
                .filter { supportedExtensions.contains($0.pathExtension.lowercased()) &&
                    ($0.lastPathComponent.contains("Screenshot") || $0.lastPathComponent.contains("Screen Recording")) }
                .map { Screenshot(url: $0) }
                .sorted { $0.createdAt > $1.createdAt }
                .prefix(30)
                .map { $0 }

            for i in loaded.indices {
                if loaded[i].isVideo {
                    loaded[i].image = Self.videoThumbnail(for: loaded[i].url)
                } else {
                    loaded[i].image = NSImage(contentsOf: loaded[i].url)
                }
            }

            screenshots = loaded
        } catch {
            print("Error loading screenshots: \(error)")
        }
    }

    private static func videoThumbnail(for url: URL) -> NSImage? {
        let asset = AVAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 400, height: 400)
        guard let cgImage = try? generator.copyCGImage(at: .zero, actualTime: nil) else { return nil }
        return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
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

    deinit {
        stopWatching()
    }
}
