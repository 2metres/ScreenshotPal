import Foundation
import Combine

class ScreenshotDirectoryManager: ObservableObject {
    enum DirectorySource {
        case osDefault
        case custom
    }

    @Published var directoryURL: URL
    @Published var source: DirectorySource

    private static let customPathKey = "customScreenshotDirectory"
    private static let gridColumnsKey = "gridColumns"

    @Published var gridColumns: Int {
        didSet {
            UserDefaults.standard.set(gridColumns, forKey: Self.gridColumnsKey)
        }
    }

    init() {
        let saved = UserDefaults.standard.integer(forKey: Self.gridColumnsKey)
        gridColumns = (1 ... 4).contains(saved) ? saved : 3
        if let customPath = UserDefaults.standard.string(forKey: Self.customPathKey) {
            directoryURL = URL(fileURLWithPath: customPath)
            source = .custom
        } else {
            directoryURL = Self.detectOSDefault()
            source = .osDefault
        }
    }

    var displayPath: String {
        let homePath = FileManager.default.homeDirectoryForCurrentUser.path
        let fullPath = directoryURL.path
        if fullPath.hasPrefix(homePath) {
            return "~" + fullPath.dropFirst(homePath.count)
        }
        return fullPath
    }

    func setCustomDirectory(_ url: URL) {
        UserDefaults.standard.set(url.path, forKey: Self.customPathKey)
        directoryURL = url
        source = .custom
    }

    func resetToOSDefault() {
        UserDefaults.standard.removeObject(forKey: Self.customPathKey)
        directoryURL = Self.detectOSDefault()
        source = .osDefault
    }

    private static func detectOSDefault() -> URL {
        if let screencaptureDefaults = UserDefaults(suiteName: "com.apple.screencapture"),
           let location = screencaptureDefaults.string(forKey: "location")
        {
            let expanded = (location as NSString).expandingTildeInPath
            let url = URL(fileURLWithPath: expanded)
            if FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }
        return FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
    }
}
