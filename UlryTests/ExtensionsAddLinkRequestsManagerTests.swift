import XCTest
@testable import Ulry

final class ExtensionsAddLinkRequestsManagerTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!
    private var directory: URL!
    private var manager: ExtensionsAddLinkRequestsManager!

    override func setUp() {
        super.setUp()
        suiteName = "UlryTests.pendingLinks.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        manager = ExtensionsAddLinkRequestsManager(defaults: defaults, directory: directory)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        try! FileManager.default.removeItem(at: directory)
        directory = nil
        manager = nil
        defaults = nil
        super.tearDown()
    }

    func testAcknowledgementPreservesFailedAndNewRequests() {
        manager.add("https://example.com/saved", note: "Saved", tagIds: ["tag"], groupId: "group")
        manager.add("https://example.com/failed", note: nil)
        let batch = manager.pendingLinks
        manager.add("https://example.com/new", note: "Added during import")
        let newRequest = manager.pendingLinks.last!

        manager.remove([batch[0]])

        XCTAssertEqual(manager.pendingLinks, [batch[1], newRequest])
    }

    func testAcknowledgementRemovesOnlyOneMatchingOccurrence() throws {
        let request = ExtensionsAddLinkRequests(url: "https://example.com", note: nil)
        defaults.set(try JSONEncoder().encode([request, request]), forKey: "pendingLinks")

        manager.remove([request])

        XCTAssertEqual(manager.pendingLinks, [request])
    }

    func testEmptyAcknowledgementKeepsPendingRequests() {
        manager.add("https://example.com", note: nil)
        let batch = manager.pendingLinks

        manager.remove([])

        XCTAssertEqual(manager.pendingLinks, batch)
    }

    func testLegacyRequestsStillDecode() throws {
        defaults.set(Data(#"[{"url":"https://example.com","note":"Legacy","date":123}]"#.utf8), forKey: "pendingLinks")

        let request = try XCTUnwrap(manager.pendingLinks.first)
        XCTAssertEqual(request.url, "https://example.com")
        XCTAssertEqual(request.date, 123)
        XCTAssertNil(request.tagIds)
        XCTAssertNil(request.groupId)
        manager.remove([request])
        XCTAssertTrue(manager.pendingLinks.isEmpty)
    }

    func testConcurrentAcknowledgementAndSavePreserveNewRequest() throws {
        for index in 0..<30 {
            manager.clearAll()
            XCTAssertTrue(manager.add("https://example.com/saved", note: nil))
            let batch = manager.pendingLinks
            let otherManager = ExtensionsAddLinkRequestsManager(defaults: defaults, directory: directory)
            let start = DispatchSemaphore(value: 0)
            let finished = DispatchGroup()
            finished.enter()
            DispatchQueue.global().async {
                start.wait()
                self.manager.remove(batch)
                finished.leave()
            }
            finished.enter()
            DispatchQueue.global().async {
                start.wait()
                otherManager.add("https://example.com/new/\(index)", note: nil)
                finished.leave()
            }
            start.signal()
            start.signal()
            XCTAssertEqual(finished.wait(timeout: .now() + 5), .success)
            XCTAssertEqual(manager.pendingLinks.map(\.url), ["https://example.com/new/\(index)"])
        }
    }

    func testConcurrentWritersEnforceLimitWithoutLosingRequests() {
        DispatchQueue.concurrentPerform(iterations: 30) { index in
            let writer = ExtensionsAddLinkRequestsManager(defaults: defaults, directory: directory)
            writer.add("https://example.com/\(index)", note: nil)
        }
        XCTAssertEqual(manager.pendingLinks.count, 15)
        XCTAssertEqual(Set(manager.pendingLinks.map(\.url)).count, 15)
        XCTAssertFalse(manager.add("https://example.com/overflow", note: nil))
    }

    func testLegacyQueueMigratesOnlyOnce() throws {
        defaults.set(Data(#"[{"url":"https://example.com/legacy","date":123}]"#.utf8), forKey: "pendingLinks")
        XCTAssertEqual(manager.pendingLinks.count, 1)
        XCTAssertNil(defaults.data(forKey: "pendingLinks"))
        manager.clearAll()
        defaults.set(Data(#"[{"url":"https://example.com/stale","date":123}]"#.utf8), forKey: "pendingLinks")
        let otherManager = ExtensionsAddLinkRequestsManager(defaults: defaults, directory: directory)
        XCTAssertTrue(otherManager.pendingLinks.isEmpty)
    }

    func testCorruptQueueIsNotOverwrittenBySave() throws {
        let url = directory.appendingPathComponent("pendingLinks.json")
        let corrupt = Data("not JSON".utf8)
        try corrupt.write(to: url)
        XCTAssertFalse(manager.add("https://example.com", note: nil))
        XCTAssertEqual(try Data(contentsOf: url), corrupt)
    }

    func testForegroundDuringImportSchedulesOneMorePass() {
        var state = ExternalLinkImportState()
        XCTAssertTrue(state.begin())
        XCTAssertFalse(state.begin())
        XCTAssertFalse(state.begin())
        XCTAssertTrue(state.finish())
        XCTAssertTrue(state.begin())
        XCTAssertFalse(state.finish())
        XCTAssertTrue(state.begin())
        XCTAssertFalse(state.finish())
    }
}
