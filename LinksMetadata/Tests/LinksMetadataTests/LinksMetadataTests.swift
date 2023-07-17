import XCTest
@testable import LinksMetadata

private let urls: [URL] = [
    "https://www.avanderlee.com/swift/operations/",
    "https://www.swiftbysundell.com/podcast/121/",
    "https://www.rfc-editor.org/rfc/rfc6762#page-5",
    "https://stackoverflow.com/questions/75790728/how-to-write-list-of-json-string-to-json-file-in-java"
]
.map { URL(string: $0)! }

final class LinksMetadataTests: XCTestCase {
    let queue = LinkDataQueue(headerFields: ["User-Agent":"Ulry"])

    func testWebsite1() throws {
        let html = try String(contentsOf: urls[0])
        guard let og = DefaultOpenGraphData(html: html) else { XCTFail(); return }
        XCTAssertEqual(Optional("Getting started with Operations and OperationQueues in Swift"), og.ogTitle)
        XCTAssertEqual(Optional("Get the most out of operations and the OperationQueue in Swift. Separate concern, add dependencies, track progress and completion with custom operations."), og.ogDescription)
        XCTAssertEqual(Optional("SwiftLee"), og.ogSiteName)
        XCTAssertEqual(Optional("https://www.avanderlee.com/swift/operations/"), og.url)
        XCTAssertEqual(Optional("https://swiftlee-banners.herokuapp.com/imagegenerator.php?title=Getting+started+with+Operations+and+OperationQueues+in+Swift"), og.ogImageUrl)
    }

    func testWebsite2() throws {
        let html = try String(contentsOf: urls[1])
        guard let og = DefaultOpenGraphData(html: html) else { XCTFail(); return }
        XCTAssertEqual(Optional("121: “Responsive and smooth UIs”, with special guest Adam Bell | Swift by Sundell"), og.ogTitle)
        XCTAssertEqual(Optional("Adam Bell returns to the podcast to discuss different techniques and approaches for optimizing UI code, and how to utilize tools like animations in order to build iOS apps that feel fast and responsive."), og.ogDescription)
        XCTAssertEqual(Optional("Swift by Sundell"), og.ogSiteName)
        XCTAssertEqual(Optional("https://www.swiftbysundell.com/podcast/121"), og.url)
        XCTAssertEqual(Optional("https://www.swiftbysundell.com/images/podcast/121.png"), og.ogImageUrl)
        XCTAssertEqual(Optional("121: “Responsive and smooth UIs”, with special guest Adam Bell | Swift by Sundell"), og.ogTitle)
    }

    func testWebsite3() throws {
        let html = try String(contentsOf: urls[2])
        guard let og = DefaultOpenGraphData(html: html) else { XCTFail(); return }
        XCTAssertEqual(Optional("RFC 6762: Multicast DNS"), og.ogTitle)
    }
}
