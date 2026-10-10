import XCTest
import Account
import Links
import UIKit
@testable import Ulry

final class ReadingHomeTests: XCTestCase {
    private var temporaryDirectories: [URL] = []

    override func tearDownWithError() throws {
        // Test-local accounts have been released before their databases are removed.
        for directory in temporaryDirectories {
            try FileManager.default.removeItem(at: directory)
        }
        temporaryDirectories.removeAll()
        try super.tearDownWithError()
    }

    @MainActor
    private func makeAccount() throws -> (Account, URL) {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        temporaryDirectories.append(directory)
        let account = Account(dataFolder: directory.path, type: .local, accountID: "home-test", imageCache: ImageStorage.shared)
        return (account, directory)
    }

    @MainActor
    func testActiveLibraryPreservesIdentityAndRelationships() async throws {
        let (account, _) = try makeAccount()
        let group = Links.Group(colorHex: "123456", iconName: "book", name: "Unread")
        let tag = Tag(colorHex: "654321", name: "Research")
        await account.insert(group: group)
        await account.insert(tag: tag)
        let older = Links.Link(url: "https://example.com/older")
        older.createdAt = 100
        let newer = Links.Link(url: "https://example.com/newer", note: "My note")
        newer.createdAt = 200
        newer.ogTitle = "Saved article"
        newer.starred = true
        newer.group = group
        newer.tags = [tag]
        let archived = Links.Link(url: "https://example.com/archived")
        archived.archived = true
        archived.createdAt = 300
        await account.insertWithNoProcessing(links: [older, newer, archived])

        let links = try await account.fetchActiveLinks()

        XCTAssertEqual(links.map(\.id), [newer.id, older.id])
        let article = ReadingHomeArticle(link: try XCTUnwrap(links.first))
        XCTAssertEqual(article.id, newer.id)
        XCTAssertEqual(article.title, "Saved article")
        XCTAssertEqual(article.summary, "My note")
        XCTAssertEqual(article.collection, "Unread")
        XCTAssertEqual(article.tags, ["Research"])
        XCTAssertTrue(article.isStarred)
        XCTAssertEqual(article.savedAt.timeIntervalSince1970, 200)
    }

    @MainActor
    func testReadAndStarChangesKeepRelationshipsAfterReload() async throws {
        let (account, _) = try makeAccount()
        let group = Links.Group(colorHex: "123456", iconName: "book", name: "Reading")
        let tag = Tag(colorHex: "654321", name: "Research")
        await account.insert(group: group)
        await account.insert(tag: tag)
        let link = Links.Link(url: "https://example.com/saved")
        link.group = group
        link.tags = [tag]
        await account.insertWithNoProcessing(links: [link])
        let loadedLinks = try await account.fetchActiveLinks()
        let loaded = try XCTUnwrap(loadedLinks.first)
        loaded.unread = false
        loaded.starred = true

        await account.update(link: loaded)
        let refreshedLinks = try await account.fetchActiveLinks()
        let refreshed = try XCTUnwrap(refreshedLinks.first)

        XCTAssertFalse(refreshed.unread)
        XCTAssertTrue(refreshed.starred)
        XCTAssertEqual(refreshed.group?.id, group.id)
        XCTAssertEqual(refreshed.tags?.map(\.id), [tag.id])
    }

    @MainActor
    func testLiveHomeStartsWithoutSampleArticles() throws {
        let (account, _) = try makeAccount()
        let home = ReadingHomeViewController(account: account)
        home.loadViewIfNeeded()
        let table = try XCTUnwrap(home.view.subviews.compactMap { $0 as? UITableView }.first)

        XCTAssertEqual(table.numberOfSections, 2)
        XCTAssertNil(table.backgroundView)
        XCTAssertNotNil(home.navigationItem.leftBarButtonItem)
        XCTAssertNil(home.navigationItem.searchController)
        XCTAssertNil(home.navigationItem.title)
        XCTAssertEqual(home.navigationItem.largeTitleDisplayMode, .never)
    }

    @MainActor
    func testFirstFrameShowsRealCardsAndFullLibraryCounts() async throws {
        let (account, _) = try makeAccount()
        let group = Links.Group(colorHex: "123456", iconName: "book", name: "Research")
        await account.insert(group: group)
        var links: [Links.Link] = []
        for index in 0..<12 {
            let link = Links.Link(url: "https://example.com/\(index)")
            link.createdAt = Int32(index + 100)
            link.ogTitle = index == 0 ? "Older unread article" : "Article \(index)"
            link.unread = index == 0
            link.starred = index.isMultiple(of: 3)
            link.group = group
            links.append(link)
        }
        let archived = Links.Link(url: "https://example.com/archive")
        archived.archived = true
        archived.starred = true
        await account.insertWithNoProcessing(links: links + [archived])

        let overview = try account.fetchHomeOverview()
        XCTAssertEqual(overview.links.count, 5)
        XCTAssertTrue(overview.links.contains { $0.id == links[0].id })
        XCTAssertEqual(overview.allCount, 12)
        XCTAssertEqual(overview.unreadCount, 1)
        XCTAssertEqual(overview.starredCount, 4)
        XCTAssertEqual(overview.groupCounts[group.id], 12)

        // No appearance callback or async refresh has run: these are first-frame cells.
        let home = ReadingHomeViewController(account: account)
        home.loadViewIfNeeded()
        let table = try XCTUnwrap(home.view.subviews.compactMap { $0 as? UITableView }.first)
        XCTAssertNil(table.backgroundView)
        let featured = try XCTUnwrap(table.dataSource?.tableView(table, cellForRowAt: IndexPath(row: 0, section: 0)))
        XCTAssertTrue(labels(in: featured).contains("Older unread article"))
        let shortcuts = try XCTUnwrap(table.dataSource?.tableView(table, cellForRowAt: IndexPath(row: 0, section: 1)))
        let counts = labels(in: shortcuts)
        XCTAssertTrue(counts.contains("12"))
        XCTAssertTrue(counts.contains("1"))
        XCTAssertTrue(counts.contains("4"))
    }

    @MainActor
    func testCollectionShelfHandlesTemporaryTableRowHeights() throws {
        var content = ReadingHomeContent.sample
        content.collections = ["Collection with a longer name", "Design notes"]
        let home = ReadingHomeViewController(content: content)
        home.loadViewIfNeeded()
        let table = try XCTUnwrap(home.view.subviews.compactMap { $0 as? UITableView }.first)
        let sizing = HomeRowHeightDelegate()
        table.delegate = sizing
        home.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        let indexPath = IndexPath(row: 0, section: table.numberOfSections - 1)
        for height: CGFloat in [111.667, 131.333, 130.333, 44] {
            sizing.height = height
            table.reloadData()
            home.view.setNeedsLayout()
            home.view.layoutIfNeeded()
            table.scrollToRow(at: indexPath, at: .bottom, animated: false)
            table.layoutIfNeeded()
            let cell = try XCTUnwrap(table.cellForRow(at: indexPath))
            let shelf = try XCTUnwrap(cell.contentView.subviews.compactMap { $0 as? UIScrollView }.first)
            XCTAssertEqual(cell.bounds.height, height, accuracy: 0.5)
            XCTAssertGreaterThanOrEqual(shelf.bounds.height, 80)
            XCTAssertFalse(shelf.hasAmbiguousLayout)
        }
    }

    @MainActor
    func testArticleCardsKeepSquareImagesDuringTemporaryRowSizing() throws {
        let home = ReadingHomeViewController(content: .sample)
        home.loadViewIfNeeded()
        let table = try XCTUnwrap(home.view.subviews.compactMap { $0 as? UITableView }.first)
        let sizing = HomeRowHeightDelegate()
        table.delegate = sizing
        home.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        for height: CGFloat in [122.333, 100, 44] {
            sizing.height = height
            table.reloadData()
            home.view.setNeedsLayout()
            home.view.layoutIfNeeded()
            table.layoutIfNeeded()
            for section in [0, 2] {
                let cell = try XCTUnwrap(table.cellForRow(at: IndexPath(row: 0, section: section)))
                let image = try XCTUnwrap(images(in: cell.contentView).first { $0.accessibilityIdentifier == "ReadingHomeArticle.thumbnail" })
                let expectedSize: CGFloat = section == 0 ? 44 : 64
                XCTAssertEqual(cell.bounds.height, height, accuracy: 0.5)
                // SF Symbols have alignment insets; Auto Layout sizes that rect.
                let alignment = image.alignmentRect(forFrame: image.frame)
                XCTAssertEqual(alignment.width, expectedSize, accuracy: 0.01)
                XCTAssertEqual(alignment.height, expectedSize, accuracy: 0.01)
                XCTAssertFalse(image.hasAmbiguousLayout)
            }
        }
    }

    @MainActor
    private func images(in view: UIView) -> [UIImageView] {
        let ownImage = (view as? UIImageView).map { [$0] } ?? []
        return ownImage + view.subviews.flatMap { images(in: $0) }
    }

    @MainActor
    private func labels(in view: UIView) -> [String] {
        let ownText = (view as? UILabel)?.text.map { [$0] } ?? []
        return ownText + view.subviews.flatMap { labels(in: $0) }
    }
}

@MainActor
private final class HomeRowHeightDelegate: NSObject, UITableViewDelegate {
    var height: CGFloat = 122.333
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { height }
}
