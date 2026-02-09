import XCTest
import Combine
@testable import ScreenPal

final class ScreenshotStoreTests: XCTestCase {
    private var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        super.tearDown()
        try? FileManager.default.removeItem(at: tempDir)
    }

    // MARK: - Helpers

    private func createFile(_ name: String) {
        let url = tempDir.appendingPathComponent(name)
        FileManager.default.createFile(atPath: url.path, contents: Data(repeating: 0, count: 100))
    }

    private func createPNG(_ name: String = "Screenshot 2026-01-01 at 12.00.00\u{202f}PM.png") {
        createFile(name)
    }

    private func createMOV(_ name: String = "Screen Recording 2026-01-01 at 12.00.00\u{202f}PM.mov") {
        createFile(name)
    }

    // MARK: - Loading

    func testLoadsScreenshotsFromDirectory() {
        createPNG("Screenshot 1.png")
        createPNG("Screenshot 2.png")

        let store = ScreenshotStore(directory: tempDir)

        XCTAssertEqual(store.screenshots.count, 2)
    }

    func testLoadsMovFiles() {
        createMOV("Screen Recording test.mov")

        let store = ScreenshotStore(directory: tempDir)

        XCTAssertEqual(store.screenshots.count, 1)
        XCTAssertTrue(store.screenshots[0].isVideo)
    }

    func testLoadsMixedFileTypes() {
        createPNG("Screenshot test.png")
        createMOV("Screen Recording test.mov")

        let store = ScreenshotStore(directory: tempDir)

        XCTAssertEqual(store.screenshots.count, 2)

        let videos = store.screenshots.filter { $0.isVideo }
        let images = store.screenshots.filter { !$0.isVideo }
        XCTAssertEqual(videos.count, 1)
        XCTAssertEqual(images.count, 1)
    }

    // MARK: - Filtering

    func testIgnoresNonScreenshotPNGs() {
        createFile("vacation_photo.png")
        createFile("document.pdf")
        createPNG("Screenshot real.png")

        let store = ScreenshotStore(directory: tempDir)

        XCTAssertEqual(store.screenshots.count, 1)
        XCTAssertEqual(store.screenshots[0].filename, "Screenshot real.png")
    }

    func testIgnoresNonScreenRecordingMOVs() {
        createFile("birthday_video.mov")
        createMOV("Screen Recording real.mov")

        let store = ScreenshotStore(directory: tempDir)

        XCTAssertEqual(store.screenshots.count, 1)
        XCTAssertTrue(store.screenshots[0].isVideo)
    }

    func testIgnoresOtherFileTypes() {
        createFile("Screenshot.jpg")
        createFile("Screenshot.gif")
        createFile("Screenshot.txt")
        createPNG("Screenshot valid.png")

        let store = ScreenshotStore(directory: tempDir)

        XCTAssertEqual(store.screenshots.count, 1)
    }

    // MARK: - Sorting

    func testSortedNewestFirst() {
        let file1 = tempDir.appendingPathComponent("Screenshot A.png")
        let file2 = tempDir.appendingPathComponent("Screenshot B.png")

        FileManager.default.createFile(atPath: file1.path, contents: Data(repeating: 0, count: 100))
        // Small delay to ensure different creation times
        Thread.sleep(forTimeInterval: 0.1)
        FileManager.default.createFile(atPath: file2.path, contents: Data(repeating: 0, count: 100))

        let store = ScreenshotStore(directory: tempDir)

        XCTAssertEqual(store.screenshots.count, 2)
        XCTAssertEqual(store.screenshots[0].filename, "Screenshot B.png")
        XCTAssertEqual(store.screenshots[1].filename, "Screenshot A.png")
    }

    // MARK: - Limit

    func testLimitsTo30Items() {
        for i in 1 ... 40 {
            createPNG("Screenshot \(i).png")
        }

        let store = ScreenshotStore(directory: tempDir)

        XCTAssertEqual(store.screenshots.count, 30)
    }

    // MARK: - Empty Directory

    func testEmptyDirectory() {
        let store = ScreenshotStore(directory: tempDir)

        XCTAssertTrue(store.screenshots.isEmpty)
        XCTAssertTrue(store.thumbnails.isEmpty)
    }

    // MARK: - Update Directory

    func testUpdateDirectorySwitchesContent() throws {
        createPNG("Screenshot original.png")
        let store = ScreenshotStore(directory: tempDir)
        XCTAssertEqual(store.screenshots.count, 1)

        let newDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: newDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: newDir) }

        let newFile = newDir.appendingPathComponent("Screenshot new1.png")
        FileManager.default.createFile(atPath: newFile.path, contents: Data(repeating: 0, count: 100))
        let newFile2 = newDir.appendingPathComponent("Screenshot new2.png")
        FileManager.default.createFile(atPath: newFile2.path, contents: Data(repeating: 0, count: 100))

        store.updateDirectory(newDir)

        XCTAssertEqual(store.screenshots.count, 2)
        XCTAssertTrue(store.screenshots.allSatisfy { $0.filename.contains("new") })
    }

    func testUpdateDirectoryClearsThumbnails() throws {
        createPNG("Screenshot test.png")
        let store = ScreenshotStore(directory: tempDir)

        // Simulate a cached thumbnail
        store.thumbnails[tempDir.appendingPathComponent("Screenshot test.png")] = NSImage()

        let newDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: newDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: newDir) }

        store.updateDirectory(newDir)

        XCTAssertTrue(store.thumbnails.isEmpty)
    }

    // MARK: - File Watcher

    func testFileWatcherDetectsNewScreenshot() {
        let store = ScreenshotStore(directory: tempDir)
        XCTAssertTrue(store.screenshots.isEmpty)

        let expectation = XCTestExpectation(description: "File watcher triggers reload")

        let cancellable = store.$screenshots
            .dropFirst() // skip initial value
            .sink { screenshots in
                if screenshots.count == 1 {
                    expectation.fulfill()
                }
            }

        // Add a file after store is watching
        createPNG("Screenshot new.png")

        wait(for: [expectation], timeout: 5.0)
        cancellable.cancel()

        XCTAssertEqual(store.screenshots.count, 1)
    }

    func testFileWatcherDetectsDeletion() throws {
        createPNG("Screenshot deleteme.png")
        let store = ScreenshotStore(directory: tempDir)
        XCTAssertEqual(store.screenshots.count, 1)

        let expectation = XCTestExpectation(description: "File watcher detects deletion")

        let cancellable = store.$screenshots
            .dropFirst()
            .sink { screenshots in
                if screenshots.isEmpty {
                    expectation.fulfill()
                }
            }

        try FileManager.default.removeItem(at: tempDir.appendingPathComponent("Screenshot deleteme.png"))

        wait(for: [expectation], timeout: 5.0)
        cancellable.cancel()

        XCTAssertTrue(store.screenshots.isEmpty)
    }

    // MARK: - Selection State

    func testSelectedIDStartsNil() {
        let store = ScreenshotStore(directory: tempDir)

        XCTAssertNil(store.selectedID)
    }

    func testSelectedIDCanBeSet() {
        createPNG("Screenshot test.png")
        let store = ScreenshotStore(directory: tempDir)

        let id = store.screenshots[0].id
        store.selectedID = id

        XCTAssertEqual(store.selectedID, id)
    }

    // MARK: - Thumbnail Cache

    func testThumbnailsStartEmpty() {
        createPNG("Screenshot test.png")
        let store = ScreenshotStore(directory: tempDir)

        // Thumbnails are generated async, so initially empty
        // (the QL generator runs in background)
        XCTAssertNotNil(store.thumbnails)
    }

    func testReloadPreservesCachedThumbnails() {
        createPNG("Screenshot test.png")
        let store = ScreenshotStore(directory: tempDir)

        let url = tempDir.appendingPathComponent("Screenshot test.png")
        let fakeThumb = NSImage(size: NSSize(width: 10, height: 10))
        store.thumbnails[url] = fakeThumb

        store.loadScreenshots()

        // Thumbnail should still be in the dictionary after reload
        XCTAssertNotNil(store.thumbnails[url])
    }

    // MARK: - Unicode Filenames (macOS uses narrow no-break space U+202F)

    func testHandlesNarrowNoBreakSpaceInFilename() {
        // macOS screenshot filenames contain U+202F between time components
        let name = "Screenshot 2026-01-01 at 12.00.00\u{202f}PM.png"
        createFile(name)

        let store = ScreenshotStore(directory: tempDir)

        XCTAssertEqual(store.screenshots.count, 1)
        XCTAssertTrue(store.screenshots[0].filename.contains("\u{202f}"))
    }
}
