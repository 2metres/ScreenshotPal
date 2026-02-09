import XCTest
@testable import ScreenPal

final class ScreenshotTests: XCTestCase {
    // MARK: - Screenshot Model

    func testScreenshotFromPNG() {
        let url = URL(fileURLWithPath: "/tmp/Screenshot 2026-01-01 at 12.00.00 PM.png")
        let screenshot = Screenshot(url: url)

        XCTAssertEqual(screenshot.filename, "Screenshot 2026-01-01 at 12.00.00 PM.png")
        XCTAssertEqual(screenshot.url, url)
        XCTAssertFalse(screenshot.isVideo)
    }

    func testScreenshotFromMOV() {
        let url = URL(fileURLWithPath: "/tmp/Screen Recording 2026-01-01 at 12.00.00 PM.mov")
        let screenshot = Screenshot(url: url)

        XCTAssertTrue(screenshot.isVideo)
        XCTAssertEqual(screenshot.filename, "Screen Recording 2026-01-01 at 12.00.00 PM.mov")
    }

    func testScreenshotIsVideoCaseInsensitive() {
        let url = URL(fileURLWithPath: "/tmp/Screen Recording.MOV")
        let screenshot = Screenshot(url: url)

        XCTAssertTrue(screenshot.isVideo)
    }

    func testScreenshotUniqueIDs() {
        let url = URL(fileURLWithPath: "/tmp/Screenshot.png")
        let a = Screenshot(url: url)
        let b = Screenshot(url: url)

        XCTAssertNotEqual(a.id, b.id, "Each Screenshot instance should have a unique UUID")
    }

    func testScreenshotEquality() {
        let url = URL(fileURLWithPath: "/tmp/Screenshot.png")
        let a = Screenshot(url: url)
        let b = a // same value, same id

        XCTAssertEqual(a, b)
    }

    func testScreenshotCreatedAtFallback() {
        // Non-existent file should fallback to Date()
        let url = URL(fileURLWithPath: "/tmp/nonexistent_Screenshot.png")
        let screenshot = Screenshot(url: url)
        let now = Date()

        XCTAssertEqual(
            screenshot.createdAt.timeIntervalSinceReferenceDate,
            now.timeIntervalSinceReferenceDate,
            accuracy: 2.0
        )
    }

    func testScreenshotCreatedAtFromFile() {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("Screenshot test file.png")
        FileManager.default.createFile(atPath: tmp.path, contents: Data())
        defer { try? FileManager.default.removeItem(at: tmp) }

        let screenshot = Screenshot(url: tmp)
        let now = Date()

        XCTAssertEqual(
            screenshot.createdAt.timeIntervalSinceReferenceDate,
            now.timeIntervalSinceReferenceDate,
            accuracy: 2.0
        )
    }
}
