import XCTest
@testable import ScreenPal

final class ScreenshotDirectoryManagerTests: XCTestCase {
    private let customPathKey = "customScreenshotDirectory"

    override func tearDown() {
        super.tearDown()
        UserDefaults.standard.removeObject(forKey: customPathKey)
    }

    // MARK: - Initialization

    func testDefaultInitUsesOSDefault() {
        UserDefaults.standard.removeObject(forKey: customPathKey)
        let manager = ScreenshotDirectoryManager()

        XCTAssertEqual(manager.source, .osDefault)
        // Should be a valid directory (either OS-detected or ~/Desktop fallback)
        XCTAssertTrue(FileManager.default.fileExists(atPath: manager.directoryURL.path))
    }

    func testInitWithCustomPathStored() {
        let customPath = FileManager.default.temporaryDirectory.path
        UserDefaults.standard.set(customPath, forKey: customPathKey)

        let manager = ScreenshotDirectoryManager()

        XCTAssertEqual(manager.source, .custom)
        XCTAssertEqual(manager.directoryURL.path, customPath)
    }

    // MARK: - Set Custom Directory

    func testSetCustomDirectory() {
        let manager = ScreenshotDirectoryManager()
        let customURL = FileManager.default.temporaryDirectory

        manager.setCustomDirectory(customURL)

        XCTAssertEqual(manager.directoryURL, customURL)
        XCTAssertEqual(manager.source, .custom)
        XCTAssertEqual(UserDefaults.standard.string(forKey: customPathKey), customURL.path)
    }

    // MARK: - Reset to Default

    func testResetToOSDefault() {
        let manager = ScreenshotDirectoryManager()
        let customURL = FileManager.default.temporaryDirectory
        manager.setCustomDirectory(customURL)

        manager.resetToOSDefault()

        XCTAssertEqual(manager.source, .osDefault)
        XCTAssertNil(UserDefaults.standard.string(forKey: customPathKey))
        XCTAssertTrue(FileManager.default.fileExists(atPath: manager.directoryURL.path))
    }

    // MARK: - Display Path

    func testDisplayPathAbbreviatesHome() {
        let manager = ScreenshotDirectoryManager()
        let home = FileManager.default.homeDirectoryForCurrentUser
        manager.setCustomDirectory(home.appendingPathComponent("Desktop"))

        XCTAssertEqual(manager.displayPath, "~/Desktop")
    }

    func testDisplayPathNonHomePath() {
        let manager = ScreenshotDirectoryManager()
        manager.setCustomDirectory(URL(fileURLWithPath: "/tmp"))

        // /tmp may resolve to /private/tmp on macOS
        XCTAssertTrue(manager.displayPath.hasPrefix("/"))
        XCTAssertFalse(manager.displayPath.hasPrefix("~"))
    }

    // MARK: - Persistence Round-Trip

    func testCustomDirectoryPersistsAcrossInstances() {
        let customURL = FileManager.default.temporaryDirectory

        let manager1 = ScreenshotDirectoryManager()
        manager1.setCustomDirectory(customURL)

        let manager2 = ScreenshotDirectoryManager()
        XCTAssertEqual(manager2.source, .custom)
        XCTAssertEqual(manager2.directoryURL.path, customURL.path)
    }

    func testResetPersistsAcrossInstances() {
        let manager1 = ScreenshotDirectoryManager()
        manager1.setCustomDirectory(FileManager.default.temporaryDirectory)
        manager1.resetToOSDefault()

        let manager2 = ScreenshotDirectoryManager()
        XCTAssertEqual(manager2.source, .osDefault)
    }
}
