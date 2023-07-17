import XCTest
@testable import Links

final class LinksTests: XCTestCase {
    func testLinkEqual() {
        let link1 = Link(url: "https://example.com")
        let link2 = Link(url: "https://example.com")
        XCTAssertFalse(link1 === link2)

        let link3 = Link(url: "https://example.com")
        link3.colorHex = "#aaffaa"
        let link4 = Link(url: "https://example.com")
        link4.colorHex = "#aaffaa"
        XCTAssertTrue(link3 === link4)

        let tags1 = [Tag(colorHex: "#ffaaff", name: "tag1")]
        let tags2 = [Tag(colorHex: "#ffaaff", name: "tag2")]
        link3.tags = Set(tags1)
        XCTAssertFalse(link3 === link4)
        link4.tags = Set(tags2)
        XCTAssertFalse(link3 === link4)
        link3.tags = Set(tags2)
        XCTAssertTrue(link3 === link4)

        link3.group = Group(colorHex: "#aaffff", iconName: "icon", name: "name")
        XCTAssertFalse(link3 === link4)
        link3.group = nil
        XCTAssertTrue(link3 === link4)
    }

    func testLinkToJson() {
        let link = Link(url: "https://example.com", note: "some note")
        link.group = Group(colorHex: "312121", iconName: "icon", name: "name")
        link.tags = Set([
            Tag(colorHex: "aaaaaa", name: "namea"),
            Tag(colorHex: "bbbbbb", name: "nameb")
        ])

        XCTAssertNoThrow {
            try JSONEncoder().encode(link)
        }

        let data = try! JSONEncoder().encode(link)
        print(String(data: data, encoding: .utf8)!)
    }
}
