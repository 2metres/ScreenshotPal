import Foundation
import AppKit

struct Screenshot: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let filename: String
    let createdAt: Date
    let isVideo: Bool

    init(url: URL) {
        self.url = url
        self.filename = url.lastPathComponent
        self.createdAt = (try? FileManager.default.attributesOfItem(atPath: url.path)[.creationDate] as? Date) ?? Date()
        self.isVideo = url.pathExtension.lowercased() == "mov"
    }

    static func == (lhs: Screenshot, rhs: Screenshot) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
