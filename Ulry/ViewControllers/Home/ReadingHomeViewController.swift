// The app Home screen uses the shared Account. Xcode previews use isolated sample content.

import UIKit
import SwiftUI
import Account
import Links
import SafariServices

struct ReadingHomeArticle {
    var id = UUID()
    let title: String
    let url: URL
    let summary: String
    let symbol: String
    let color: UIColor
    let savedAt: Date
    var isUnread = true
    var isStarred = false
    var isArchived = false
    var collection: String?
    var tags: [String] = []

    var sourceURLString: String?
    var domain: String {
        let source = sourceURLString ?? url.absoluteString
        return (URL(string: source)?.host ?? source).replacingOccurrences(of: "www.", with: "")
    }
}

extension ReadingHomeArticle {
    init(link: Links.Link) {
        let title = link.ogTitle?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        self.init(
            id: link.id,
            title: title.isEmpty ? link.url : title,
            url: URL(string: link.url) ?? URL(string: "about:blank")!,
            summary: link.ogDescription ?? link.note ?? "",
            symbol: link.group?.iconName ?? "link",
            color: UIColor(hex: link.colorHex) ?? .systemIndigo,
            savedAt: Date(timeIntervalSince1970: TimeInterval(link.createdAt)),
            isUnread: link.unread,
            isStarred: link.starred,
            isArchived: link.archived,
            collection: link.group?.name,
            tags: link.tags?.map(\.name).sorted() ?? [],
            sourceURLString: link.url
        )
    }
}

struct ReadingHomeContent {
    var articles: [ReadingHomeArticle]
    var collections: [String]
    var tags: [String]

    static var sample: Self {
        let now = Date()
        return Self(articles: [
            ReadingHomeArticle(title: "The quiet joy of doing one thing at a time", url: URL(string: "https://www.zenhabits.net/simple")!, summary: "A small reminder to slow down, pay attention, and make room for what matters.", symbol: "leaf", color: .systemTeal, savedAt: now, collection: "Slow living", tags: ["Mindfulness"]),
            ReadingHomeArticle(title: "Good design starts with a better question", url: URL(string: "https://www.design.google/library")!, summary: "New perspectives on the things we make.", symbol: "square.stack.3d.up", color: .systemIndigo, savedAt: now.addingTimeInterval(-3600), isStarred: true, collection: "Design notes", tags: ["Design"]),
            ReadingHomeArticle(title: "A weekend guide to Copenhagen", url: URL(string: "https://www.visitcopenhagen.com")!, summary: "Places to wander, eat, and come back to.", symbol: "building.2", color: .systemOrange, savedAt: now.addingTimeInterval(-86400), collection: "Places to go", tags: ["Travel"]),
            ReadingHomeArticle(title: "Make something just for the fun of it", url: URL(string: "https://www.austinkleon.com")!, summary: "A little space for a creative habit.", symbol: "pencil.and.outline", color: .systemPink, savedAt: now.addingTimeInterval(-172800), isUnread: false, isStarred: true, collection: "Design notes", tags: ["Design", "Inspiration"]),
            ReadingHomeArticle(title: "Notes on a more thoughtful internet", url: URL(string: "https://www.technical.ly")!, summary: "What we choose to keep, and why.", symbol: "network", color: .systemBlue, savedAt: now.addingTimeInterval(-259200), isUnread: false, isArchived: true, tags: ["Inspiration"])
        ], collections: ["Design notes", "Slow living", "Places to go"], tags: ["Design", "Mindfulness", "Travel", "Inspiration"])
    }

    static let empty = Self(articles: [], collections: [], tags: [])
}

/// UIKit throughout. SwiftUI is used only to host this controller in Xcode previews.
/// Use init(account:) in the app, and init(content:) for isolated previews.
final class ReadingHomeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var onOpenArticle: ((ReadingHomeArticle) -> Void)?
    var onOpenLibrary: ((String) -> Void)?
    var onAddLink: (() -> Void)?
    var onOpenSettings: (() -> Void)?

    private enum Section { case next, library, recent, collections, empty, results }
    private var content: ReadingHomeContent
    private let account: Account?
    private var persistedLinks: [UUID: Links.Link] = [:]
    private var persistedGroups: [Links.Group] = []
    private var loadTask: Task<Void, Never>?
    private var pendingReload: DispatchWorkItem?
    private var hasLoadedLiveContent = false
    private var overviewCounts: (all: Int, unread: Int, starred: Int)?
    private var overviewCollectionCounts: [String: Int] = [:]
    private var hasCheckedWelcome = false
    private let table = UITableView(frame: .zero, style: .insetGrouped)
    private var sections: [Section] = []
    private var browserFilter: String?

    init(content: ReadingHomeContent = .sample) {
        self.content = content
        self.account = nil
        super.init(nibName: nil, bundle: nil)
    }

    init(account: Account) {
        self.account = account
        self.content = .empty
        super.init(nibName: nil, bundle: nil)
        // Read only the visible cards and exact counts before the first frame.
        // The full library is still refreshed asynchronously.
        if let overview = try? account.fetchHomeOverview() {
            persistedLinks = Dictionary(uniqueKeysWithValues: overview.links.map { ($0.id, $0) })
            persistedGroups = overview.groups
            content = ReadingHomeContent(articles: overview.links.map { ReadingHomeArticle(link: $0) }, collections: overview.groups.map(\.name), tags: [])
            overviewCounts = (overview.allCount, overview.unreadCount, overview.starredCount)
            for group in overview.groups { overviewCollectionCounts[group.name] = overview.groupCounts[group.id] ?? 0 }
            hasLoadedLiveContent = true
        }
    }

    deinit { loadTask?.cancel(); pendingReload?.cancel() }

    required init?(coder: NSCoder) { fatalError("Use init(content:)") }

    private var active: [ReadingHomeArticle] { content.articles.filter { !$0.isArchived } }
    private var featuredArticle: ReadingHomeArticle? { active.first { $0.isUnread } }
    private var recent: [ReadingHomeArticle] { Array(active.filter { $0.id != featuredArticle?.id }.prefix(3)) }
    private var results: [ReadingHomeArticle] {
        content.articles.filter { article in
            let matchesFilter: Bool
            switch browserFilter {
            case "Unread": matchesFilter = article.isUnread && !article.isArchived
            case "Starred": matchesFilter = article.isStarred && !article.isArchived
            case "Archive": matchesFilter = article.isArchived
            case nil, "All links": matchesFilter = !article.isArchived
            case let name?: matchesFilter = !article.isArchived && (article.collection == name || article.tags.contains(name))
            }
            return matchesFilter
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        view.tintColor = .systemIndigo
        navigationItem.title = browserFilter
        navigationItem.largeTitleDisplayMode = browserFilter == nil ? .never : .always
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.backButtonDisplayMode = .minimal
        let add = UIBarButtonItem(image: UIImage(systemName: "plus"), primaryAction: UIAction { [weak self] _ in self?.addLink() })
        add.accessibilityLabel = "Save a link"
        var libraryActions: [UIAction] = [
            UIAction(title: "Archive", image: UIImage(systemName: "archivebox")) { [weak self] _ in self?.openLibrary("Archive") },
            UIAction(title: "New collection", image: UIImage(systemName: "folder.badge.plus")) { [weak self] _ in self?.addCollection() }
        ]
        if account != nil {
            libraryActions.append(UIAction(title: "New tag", image: UIImage(systemName: "tag")) { [weak self] _ in self?.addTag() })
            libraryActions.append(UIAction(title: "Statistics", image: UIImage(systemName: "chart.bar")) { [weak self] _ in self?.showStatistics() })
        }
        let more = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), menu: UIMenu(children: libraryActions))
        more.accessibilityLabel = "Library options"
        navigationItem.rightBarButtonItems = [add, more]
        if account != nil || onOpenSettings != nil {
            let settings = UIBarButtonItem(image: UIImage(systemName: "gearshape"), primaryAction: UIAction { [weak self] _ in self?.showSettings() })
            settings.accessibilityLabel = "Settings"
            navigationItem.leftBarButtonItem = settings
        }
        definesPresentationContext = true
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (controller: ReadingHomeViewController, _: UITraitCollection) in
            controller.navigationItem.largeTitleDisplayMode = controller.browserFilter == nil || controller.traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? .never : .always
            controller.reload()
        }
        if traitCollection.preferredContentSizeCategory.isAccessibilityCategory { navigationItem.largeTitleDisplayMode = .never }

        table.translatesAutoresizingMaskIntoConstraints = false
        table.backgroundColor = .systemGroupedBackground
        table.dataSource = self
        table.delegate = self
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 100
        table.alwaysBounceVertical = true
        table.cellLayoutMarginsFollowReadableWidth = true
        table.register(ReadingArticleCell.self, forCellReuseIdentifier: "article")
        table.register(UITableViewCell.self, forCellReuseIdentifier: "content")
        view.addSubview(table)
        NSLayoutConstraint.activate([
            table.topAnchor.constraint(equalTo: view.topAnchor), table.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            table.leadingAnchor.constraint(equalTo: view.leadingAnchor), table.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        if account != nil {
            let refresh = UIRefreshControl()
            refresh.addTarget(self, action: #selector(reloadLiveContent), for: .valueChanged)
            table.refreshControl = refresh
            let changes: [Notification.Name] = [.UserDidAddLink, .UserDidUpdateLink, .UserDidDeleteLink, .UserDidAddGroup, .UserDidUpdateGroup, .UserDidDeleteGroup, .UserDidAddTag, .UserDidUpdateTag, .UserDidDeleteTag, .DidUpdateImage, UIApplication.willEnterForegroundNotification]
            for name in changes {
                NotificationCenter.default.addObserver(self, selector: #selector(scheduleLiveReload), name: name, object: nil)
            }
        }
        reload()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if account != nil { reloadLiveContent() }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard account != nil, !hasCheckedWelcome else { return }
        hasCheckedWelcome = true
        let defaults = UserDefaultsWrapper()
        if defaults.optionalGet(key: .isFirstLaunch) == true {
            present(UIHostingController(rootView: OnboardingView()), animated: true)
            defaults.set(false, forKey: .isFirstLaunch)
            defaults.set(AppData.appVersion, forKey: .lastShownWhatsNew)
        } else {
            let lastVersion: String? = defaults.optionalGet(key: .lastShownWhatsNew)
            if lastVersion != AppData.appVersion {
                present(ChangelogViewController(), animated: true)
                defaults.set(AppData.appVersion, forKey: .lastShownWhatsNew)
            }
        }
    }

    @objc private func scheduleLiveReload() {
        pendingReload?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.reloadLiveContent() }
        pendingReload = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: work)
    }

    @objc private func reloadLiveContent() {
        guard let account else { return }
        pendingReload?.cancel()
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            do {
                let links = try await account.fetchActiveLinks()
                let groups = try await account.fetchAllGroups()
                guard !Task.isCancelled, let self else { return }
                self.persistedLinks = Dictionary(uniqueKeysWithValues: links.map { ($0.id, $0) })
                self.persistedGroups = groups
                self.content = ReadingHomeContent(articles: links.map { ReadingHomeArticle(link: $0) }, collections: groups.map(\.name), tags: [])
                self.hasLoadedLiveContent = true
                self.overviewCounts = nil
                self.overviewCollectionCounts = [:]
                self.table.backgroundView = nil
                self.table.refreshControl?.endRefreshing()
                self.reload()
            } catch {
                guard !Task.isCancelled, let self else { return }
                self.table.refreshControl?.endRefreshing()
                if !self.hasLoadedLiveContent {
                    let label = ReadingHomeStyle.label("Couldn’t load your links.\nPull down to try again.", style: .body, color: .secondaryLabel)
                    label.textAlignment = .center
                    self.table.backgroundView = label
                }
            }
        }
    }

    private func reload() {
        if account != nil && !hasLoadedLiveContent { sections = [] }
        else if browserFilter != nil { sections = [.results] }
        else if active.isEmpty {
            sections = [.empty, .library]
            if !content.collections.isEmpty { sections.append(.collections) }
        }
        else {
            sections = featuredArticle == nil ? [.library] : [.next, .library]
            if !recent.isEmpty { sections.append(.recent) }
            if !content.collections.isEmpty { sections.append(.collections) }
        }
        table.reloadData()
    }

    func numberOfSections(in tableView: UITableView) -> Int { sections.count }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sections[section] {
        case .recent: return recent.count
        case .results: return max(results.count, 1)
        default: return 1
        }
    }

    private func article(at indexPath: IndexPath) -> ReadingHomeArticle? {
        switch sections[indexPath.section] {
        case .next: return featuredArticle
        case .recent: return recent[indexPath.row]
        case .results: return results.indices.contains(indexPath.row) ? results[indexPath.row] : nil
        default: return nil
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let article = article(at: indexPath) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "article", for: indexPath) as! ReadingArticleCell
            let thumbnail = account == nil ? nil : ImageStorage.shared.getImageData(filename: article.id.uuidString + ".jpeg").flatMap { UIImage(data: $0) }
            cell.configure(article, featured: sections[indexPath.section] == .next, thumbnail: thumbnail)
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "content", for: indexPath)
        cell.contentConfiguration = nil
        cell.backgroundConfiguration = .clear()
        cell.selectionStyle = .none
        cell.accessoryType = .none
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        let body: UIView
        switch sections[indexPath.section] {
        case .library: body = libraryShortcuts()
        case .collections: body = collectionShelf()
        case .empty: body = emptyState(title: "Good things, kept for later.", message: "Save an article, a useful guide, or something that catches your eye. It’ll be here when you have a moment.", action: true)
        default: body = emptyState(title: "No links here yet", message: "The next good read is only a saved link away.", action: false)
        }
        body.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(body)
        let bottom = body.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor)
        bottom.priority = .init(999)
        NSLayoutConstraint.activate([
            body.topAnchor.constraint(equalTo: cell.contentView.topAnchor), bottom,
            body.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor), body.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor)
        ])
        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let title: String
        let action: String?
        switch sections[section] {
        case .next: title = "Up next"; action = "Unread"
        case .library: return nil
        case .recent: title = "Recently saved"; action = "All links"
        case .collections: title = "Collections"; action = nil
        case .results: title = "\(results.count) links"; action = nil
        case .empty: return nil
        }
        let label = ReadingHomeStyle.label(title, style: .title3, weight: .bold)
        let row = UIStackView(arrangedSubviews: [label])
        row.alignment = .center
        row.spacing = 12
        if traitCollection.preferredContentSizeCategory.isAccessibilityCategory {
            row.axis = .vertical
            row.alignment = .leading
            row.spacing = 4
        }
        row.isLayoutMarginsRelativeArrangement = true
        row.directionalLayoutMargins = .init(top: 8, leading: 0, bottom: 12, trailing: 0)
        if let action {
            let button = UIButton(type: .system)
            button.setTitle("See all", for: .normal)
            button.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
            button.titleLabel?.adjustsFontForContentSizeCategory = true
            button.accessibilityLabel = "See all \(title.lowercased())"
            button.addAction(UIAction { [weak self] _ in self?.openLibrary(action) }, for: .touchUpInside)
            button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
            button.setContentHuggingPriority(.required, for: .horizontal)
            row.addArrangedSubview(button)
        }
        return row
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch sections[section] { case .library, .empty: return 12; default: return UITableView.automaticDimension }
    }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat { 12 }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let article = article(at: indexPath) else { return }
        if let onOpenArticle { onOpenArticle(article); return }
        if account != nil { openSavedArticle(article); return }
        let detail = UIViewController()
        detail.view.backgroundColor = .systemBackground
        detail.navigationItem.title = article.domain
        detail.navigationItem.largeTitleDisplayMode = .never
        let scroll = UIScrollView()
        let body = ReadingHomeStyle.vertical([
            ReadingHomeStyle.label(article.domain.uppercased(), style: .caption1, weight: .semibold, color: .secondaryLabel),
            ReadingHomeStyle.label(article.title, style: .largeTitle, weight: .bold, serif: true),
            ReadingHomeStyle.label(article.summary, style: .body),
            ReadingHomeStyle.label(article.url.absoluteString, style: .footnote, color: .secondaryLabel)
        ], spacing: 20)
        detail.view.addSubview(scroll)
        scroll.translatesAutoresizingMaskIntoConstraints = false
        body.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(body)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: detail.view.safeAreaLayoutGuide.topAnchor), scroll.bottomAnchor.constraint(equalTo: detail.view.bottomAnchor),
            scroll.leadingAnchor.constraint(equalTo: detail.view.leadingAnchor), scroll.trailingAnchor.constraint(equalTo: detail.view.trailingAnchor),
            body.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 28), body.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -28),
            body.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 24), body.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -24),
            body.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -48)
        ])
        navigationController?.pushViewController(detail, animated: true)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let article = article(at: indexPath) else { return nil }
        let star = UIContextualAction(style: .normal, title: article.isStarred ? "Unstar" : "Star") { [weak self] _, _, done in
            guard let self else { done(false); return }
            if self.account != nil { self.updateSavedArticle(article, star: true, completion: done); return }
            guard let i = self.content.articles.firstIndex(where: { $0.id == article.id }) else { done(false); return }
            self.content.articles[i].isStarred.toggle()
            self.reload(); done(true)
        }
        star.image = UIImage(systemName: article.isStarred ? "star.slash" : "star")
        star.backgroundColor = .systemIndigo
        let read = UIContextualAction(style: .normal, title: article.isUnread ? "Mark read" : "Mark unread") { [weak self] _, _, done in
            guard let self else { done(false); return }
            if self.account != nil { self.updateSavedArticle(article, star: false, completion: done); return }
            guard let i = self.content.articles.firstIndex(where: { $0.id == article.id }) else { done(false); return }
            self.content.articles[i].isUnread.toggle()
            self.reload(); done(true)
        }
        read.image = UIImage(systemName: article.isUnread ? "checkmark" : "circle")
        read.backgroundColor = .systemTeal
        return UISwipeActionsConfiguration(actions: [star, read])
    }

    private func libraryShortcuts() -> UIView {
        let row = UIStackView()
        row.spacing = 10
        row.distribution = .fillEqually
        row.axis = traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? .vertical : .horizontal
        let articles: [ReadingHomeArticle] = active
        let unreadCount: Int = articles.filter { $0.isUnread }.count
        let starredCount: Int = articles.filter { $0.isStarred }.count
        let shortcuts: [(name: String, symbol: String, count: Int)] = [
            ("All links", "tray", overviewCounts?.all ?? articles.count),
            ("Unread", "circle", overviewCounts?.unread ?? unreadCount),
            ("Starred", "star", overviewCounts?.starred ?? starredCount)
        ]
        for (name, symbol, count) in shortcuts {
            let button = ReadingHomeTile(title: name, subtitle: "\(count)", symbol: symbol, color: .systemIndigo, compact: true)
            button.addAction(UIAction { [weak self] _ in self?.openLibrary(name) }, for: .touchUpInside)
            row.addArrangedSubview(button)
        }
        return row
    }

    private func collectionShelf() -> UIView {
        let tiles = content.collections.map { name -> UIView in
            let count = overviewCounts == nil ? active.filter { $0.collection == name }.count : overviewCollectionCounts[name] ?? 0
            let tile = ReadingHomeTile(title: name, subtitle: "\(count) \(count == 1 ? "link" : "links")", symbol: "folder", color: .systemIndigo, compact: false)
            if !traitCollection.preferredContentSizeCategory.isAccessibilityCategory {
                tile.widthAnchor.constraint(equalToConstant: 164).isActive = true
            }
            tile.addAction(UIAction { [weak self] _ in self?.openCollection(name) }, for: .touchUpInside)
            if account != nil {
                tile.accessibilityIdentifier = name
                tile.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(collectionLongPressed(_:))))
            }
            return tile
        }
        return traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? ReadingHomeStyle.vertical(tiles, spacing: 10) : horizontalShelf(tiles)
    }

    private func horizontalShelf(_ views: [UIView]) -> UIView {
        let scroll = UIScrollView()
        scroll.showsHorizontalScrollIndicator = false
        let row = UIStackView(arrangedSubviews: views)
        row.spacing = 10
        row.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor), row.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            row.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor), row.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            row.heightAnchor.constraint(equalTo: scroll.frameLayoutGuide.heightAnchor)
        ])
        // Vertical fitting must be explicit because a scroll view has no intrinsic size.
        let height = views.map { $0.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height }.max() ?? 44
        let preferredHeight = scroll.heightAnchor.constraint(equalToConstant: max(height, 44))
        // UITableView imposes a temporary content height while measuring/reusing rows,
        // and accounts for its separator separately. Let that height take precedence.
        preferredHeight.priority = .init(999)
        preferredHeight.identifier = "ReadingHomeCollectionShelf.preferredHeight"
        preferredHeight.isActive = true
        return scroll
    }

    private func emptyState(title: String, message: String, action: Bool) -> UIView {
        let image = UIImageView(image: UIImage(systemName: "bookmark"))
        image.preferredSymbolConfiguration = .init(pointSize: 36, weight: .light)
        image.tintColor = .systemIndigo
        image.contentMode = .left
        image.heightAnchor.constraint(equalToConstant: 52).isActive = true
        image.isAccessibilityElement = false
        let body = ReadingHomeStyle.vertical([image, ReadingHomeStyle.label(title, style: .title1, weight: .bold, serif: true), ReadingHomeStyle.label(message, style: .body, color: .secondaryLabel)], spacing: 16)
        body.isLayoutMarginsRelativeArrangement = true
        body.directionalLayoutMargins = .init(top: 32, leading: 8, bottom: 32, trailing: 8)
        if action {
            let button = UIButton(type: .system)
            var config = UIButton.Configuration.filled()
            config.title = "Save your first link"
            config.baseBackgroundColor = .systemIndigo
            config.cornerStyle = .capsule
            config.contentInsets = .init(top: 14, leading: 20, bottom: 14, trailing: 20)
            button.configuration = config
            button.addAction(UIAction { [weak self] _ in self?.addLink() }, for: .touchUpInside)
            body.addArrangedSubview(button)
        }
        return body
    }

    private func openLibrary(_ name: String) {
        if let onOpenLibrary { onOpenLibrary(name); return }
        if account != nil {
            let category: Category
            switch name {
            case "Unread": category = .unread
            case "Starred": category = .starred
            case "Archive": category = .archived
            default: category = .all
            }
            pushLibrary(category)
            return
        }
        let controller = ReadingHomeViewController(content: content)
        controller.browserFilter = name
        navigationController?.pushViewController(controller, animated: true)
    }

    private func pushLibrary(_ category: Category) {
        guard let account else { return }
        let controller = LinksTableViewController()
        controller.account = account
        controller.category = category
        controller.navigationItem.titleView = CategoryTitleView.getView(for: category)
        navigationController?.pushViewController(controller, animated: true)
    }

    private func openCollection(_ name: String) {
        if account != nil {
            guard let group = persistedGroups.first(where: { $0.name == name }) else { return }
            pushLibrary(.group(group))
        } else { openLibrary(name) }
    }

    private func openSavedArticle(_ article: ReadingHomeArticle) {
        guard let account, let link = persistedLinks[article.id],
              let url = URLRedirector().redirect(link),
              ["http", "https"].contains(url.scheme?.lowercased() ?? ""), url.host != nil else {
            let alert = UIAlertController(title: "Couldn’t open link", message: "This link doesn’t contain a valid website address.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        let defaults = UserDefaultsWrapper()
        let openInApp: Bool = defaults.optionalGet(key: .openInApp) ?? false
        if openInApp {
            let configuration = SFSafariViewController.Configuration()
            configuration.entersReaderIfAvailable = defaults.optionalGet(key: .readMode) ?? false
            present(SFSafariViewController(url: url, configuration: configuration), animated: true)
        } else { UIApplication.shared.open(url) }
        Task { await AppReviewManager().registerReviewWorthyAction() }
        let markRead: Bool = defaults.optionalGet(key: .markReadOnOpen) ?? false
        if link.unread && markRead {
            link.unread = false
            Task { await account.update(link: link) }
        }
    }

    private func updateSavedArticle(_ article: ReadingHomeArticle, star: Bool, completion: @escaping (Bool) -> Void) {
        guard let account, let link = persistedLinks[article.id] else { completion(false); return }
        if star { link.starred.toggle() } else { link.unread.toggle() }
        Task { [weak self] in
            await account.update(link: link)
            completion(true)
            self?.reloadLiveContent()
        }
    }

    private func showSettings() {
        if let onOpenSettings { onOpenSettings(); return }
        guard let account else { return }
        let controller = SettingsViewController()
        controller.account = account
        let navigation = UINavigationController(rootViewController: controller)
        navigation.modalPresentationStyle = .fullScreen
        present(navigation, animated: true)
    }

    private func showStatistics() {
        guard let account else { return }
        let controller = UlryInfoViewController()
        controller.account = account
        navigationController?.pushViewController(controller, animated: true)
    }

    private func addTag() {
        guard let account else { return }
        present(UIHostingController(rootView: AddCategoryView(account: account, configuration: .tag)), animated: true)
    }

    @objc private func collectionLongPressed(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began, let account, let source = gesture.view,
              let group = persistedGroups.first(where: { $0.name == source.accessibilityIdentifier }) else { return }
        let menu = UIAlertController(title: group.name, message: nil, preferredStyle: .actionSheet)
        menu.addAction(UIAlertAction(title: "Edit", style: .default) { [weak self] _ in
            self?.present(UIHostingController(rootView: AddCategoryView(account: account, configuration: .editGroup(group))), animated: true)
        })
        menu.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            let confirmation = UIAlertController(title: "Delete \(group.name)?", message: "The links in this collection will stay in your library.", preferredStyle: .alert)
            confirmation.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            confirmation.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
                Task { await account.delete(group: group) }
            })
            self?.present(confirmation, animated: true)
        })
        menu.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        menu.popoverPresentationController?.sourceView = source
        menu.popoverPresentationController?.sourceRect = source.bounds
        present(menu, animated: true)
    }

    private func addLink() {
        if let onAddLink { onAddLink(); return }
        if let account {
            present(UIHostingController(rootView: AddLinkView(account: account)), animated: true)
            return
        }
        let alert = UIAlertController(title: "Save a link", message: "Keep something good for later.", preferredStyle: .alert)
        alert.addTextField { field in field.placeholder = "https://"; field.keyboardType = .URL; field.autocapitalizationType = .none; field.autocorrectionType = .no }
        alert.addTextField { $0.placeholder = "Title (optional)" }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self, weak alert] _ in
            guard let self, let text = alert?.textFields?.first?.text, let url = URL(string: text), ["https", "http"].contains(url.scheme?.lowercased() ?? ""), url.host != nil else { return }
            let title = alert?.textFields?.last?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            self.content.articles.insert(ReadingHomeArticle(title: title.isEmpty ? url.host! : title, url: url, summary: "", symbol: "link", color: .systemIndigo, savedAt: Date()), at: 0)
            self.reload()
        })
        present(alert, animated: true)
    }

    private func addCollection() {
        if let account {
            present(UIHostingController(rootView: AddCategoryView(account: account, configuration: .group)), animated: true)
            return
        }
        let alert = UIAlertController(title: "New collection", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Collection name" }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Create", style: .default) { [weak self, weak alert] _ in
            guard let self, let name = alert?.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty, !self.content.collections.contains(name) else { return }
            self.content.collections.append(name)
            self.reload()
        })
        present(alert, animated: true)
    }
}

private enum ReadingHomeStyle {
    static func label(_ text: String, style: UIFont.TextStyle, weight: UIFont.Weight = .regular, color: UIColor = .label, serif: Bool = false) -> UILabel {
        let label = UILabel()
        let base = UIFont.preferredFont(forTextStyle: style, compatibleWith: UITraitCollection(preferredContentSizeCategory: .large))
        let font = UIFont.systemFont(ofSize: base.pointSize, weight: weight)
        let descriptor = serif ? font.fontDescriptor.withDesign(.serif) ?? font.fontDescriptor : font.fontDescriptor
        label.font = UIFontMetrics(forTextStyle: style).scaledFont(for: UIFont(descriptor: descriptor, size: base.pointSize))
        label.adjustsFontForContentSizeCategory = true
        label.textColor = color
        label.text = text
        label.numberOfLines = 0
        return label
    }

    static func vertical(_ views: [UIView], spacing: CGFloat) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: views)
        stack.axis = .vertical
        stack.spacing = spacing
        return stack
    }
}

private final class ReadingHomeTile: UIControl {
    init(title: String, subtitle: String, symbol: String, color: UIColor, compact: Bool) {
        super.init(frame: .zero)
        backgroundColor = .secondarySystemGroupedBackground
        layer.cornerRadius = 20
        layer.cornerCurve = .continuous
        let icon = UIImageView(image: UIImage(systemName: symbol))
        icon.preferredSymbolConfiguration = .init(pointSize: compact ? 19 : 24, weight: .medium)
        icon.tintColor = color
        icon.contentMode = .left
        icon.heightAnchor.constraint(equalToConstant: 28).isActive = true
        let titleLabel = ReadingHomeStyle.label(title, style: compact ? .caption1 : .subheadline, weight: .semibold)
        let count = ReadingHomeStyle.label(subtitle, style: compact ? .title2 : .caption1, weight: compact ? .bold : .regular, color: compact ? .label : .secondaryLabel)
        let stack = ReadingHomeStyle.vertical(compact ? [icon, count, titleLabel] : [icon, titleLabel, count], spacing: compact ? 5 : 10)
        stack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 16), stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16), stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
        ])
        isAccessibilityElement = true
        accessibilityLabel = "\(title), \(subtitle)"
        accessibilityTraits = .button
    }
    required init?(coder: NSCoder) { fatalError("Use init(title:subtitle:symbol:color:compact:)") }
    override var isHighlighted: Bool { didSet { alpha = isHighlighted ? 0.6 : 1 } }
}

private final class ReadingArticleCell: UITableViewCell {
    private let body = UIStackView()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        body.axis = .vertical
        body.spacing = 12
        body.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(body)
        // Keep the card's internal geometry intact while UITableView temporarily
        // imposes a row height that is smaller than its self-sized content.
        let bottom = body.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        bottom.priority = .init(999)
        NSLayoutConstraint.activate([
            body.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20), bottom,
            body.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor), body.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor)
        ])
    }
    required init?(coder: NSCoder) { fatalError("Use init(style:reuseIdentifier:)") }

    func configure(_ article: ReadingHomeArticle, featured: Bool, thumbnail: UIImage? = nil) {
        body.arrangedSubviews.forEach { $0.removeFromSuperview() }
        backgroundColor = .secondarySystemGroupedBackground
        accessoryType = featured ? .none : .disclosureIndicator
        let source = ReadingHomeStyle.label(article.domain, style: .caption1, weight: .semibold, color: .secondaryLabel)
        let title = ReadingHomeStyle.label(article.title, style: featured ? .title1 : .headline, weight: .bold, serif: featured)
        let date: String
        if Calendar.current.isDateInToday(article.savedAt) { date = "today" }
        else if Calendar.current.isDateInYesterday(article.savedAt) { date = "yesterday" }
        else { date = RelativeDateTimeFormatter().localizedString(for: article.savedAt, relativeTo: Date()) }
        let metadata = ReadingHomeStyle.label("Saved \(date)\(article.isStarred ? " · Starred" : "")", style: .caption1, color: .secondaryLabel)
        let icon = UIImageView(image: UIImage(systemName: article.symbol))
        icon.accessibilityIdentifier = "ReadingHomeArticle.thumbnail"
        icon.preferredSymbolConfiguration = .init(pointSize: featured ? 23 : 27, weight: .regular)
        icon.tintColor = article.color
        icon.backgroundColor = article.color.withAlphaComponent(0.10)
        icon.contentMode = .center
        if let thumbnail { icon.image = thumbnail; icon.contentMode = .scaleAspectFill; icon.clipsToBounds = true }
        icon.layer.cornerRadius = featured ? 12 : 16
        icon.widthAnchor.constraint(equalToConstant: featured ? 44 : 64).isActive = true
        icon.heightAnchor.constraint(equalTo: icon.widthAnchor).isActive = true
        if featured {
            let top = UIStackView(arrangedSubviews: [icon, source])
            top.alignment = .center
            top.spacing = 10
            body.addArrangedSubview(top)
            body.addArrangedSubview(title)
            if !article.summary.isEmpty { body.addArrangedSubview(ReadingHomeStyle.label(article.summary, style: .subheadline, color: .secondaryLabel)) }
            let callToAction = ReadingHomeStyle.label("Start reading  →", style: .subheadline, weight: .semibold, color: .systemIndigo)
            let bottom = UIStackView(arrangedSubviews: [callToAction, metadata])
            bottom.spacing = 12
            bottom.alignment = .center
            bottom.axis = traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? .vertical : .horizontal
            body.addArrangedSubview(bottom)
            body.setCustomSpacing(20, after: title)
        } else {
            let text = ReadingHomeStyle.vertical([source, title, metadata], spacing: 6)
            let row = UIStackView(arrangedSubviews: [text, icon])
            row.alignment = .center
            row.spacing = 16
            if traitCollection.preferredContentSizeCategory.isAccessibilityCategory { row.axis = .vertical; row.alignment = .leading }
            body.addArrangedSubview(row)
        }
        isAccessibilityElement = true
        accessibilityLabel = "\(article.title), \(article.domain), \(metadata.text ?? "")"
        accessibilityHint = "Opens saved link"
        accessibilityTraits = .button
    }
}

// MARK: - Xcode previews (no database, network, or changes to your saved links)

struct ReadingHomePreview: UIViewControllerRepresentable {
    var content: ReadingHomeContent = .sample
    func makeUIViewController(context: Context) -> UINavigationController {
        UINavigationController(rootViewController: ReadingHomeViewController(content: content))
    }
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}

#Preview("Reading Home · Light") { ReadingHomePreview().ignoresSafeArea() }
#Preview("Reading Home · Dark") { ReadingHomePreview().ignoresSafeArea().preferredColorScheme(.dark) }
#Preview("Reading Home · Empty") { ReadingHomePreview(content: .empty).ignoresSafeArea() }
#Preview("Reading Home · Large text") { ReadingHomePreview().ignoresSafeArea().environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge) }
