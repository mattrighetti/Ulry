//
//  LinksTableViewController.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/8/22.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import UIKit
import Links
import CoreData
import SwiftUI
import SafariServices
import LinksDatabase
import Account
import Lottie
import LinksMetadata

private var reuseIdentifier = "LinkCell"

class LinksTableViewController: UIViewController {
    var account: Account!

    var snapshotCache: NSDiffableDataSourceSnapshot<Int, String>!
    
    var category: Category?
    
    var orderBy: OrderBy {
        get {
            if let orderByValue: String = UserDefaultsWrapper().optionalGet(key: .orderBy) {
                return OrderBy(rawValue: orderByValue)!
            }
            return OrderBy.newest
        }
        set {
            UserDefaultsWrapper().set(newValue.rawValue, forKey: .orderBy)
            setRightBarButtonItems(animated: true)
            loadLinks()
        }
    }
    
    lazy var tableview: UITableView = {
        let tableview = UITableView()
        tableview.backgroundColor = UIColor(named: "bg-color")
        tableview.register(LinkCell.self, forCellReuseIdentifier: LinkCell.reuseIdentifier)
        tableview.rowHeight = UITableView.automaticDimension
        tableview.estimatedRowHeight = 200
        tableview.isPrefetchingEnabled = true
        tableview.translatesAutoresizingMaskIntoConstraints = false
        return tableview
    }()

    lazy var emptyResultAnimatedView: EmptinessView = {
        let view = EmptinessView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    var filterButton: UIBarButtonItem {
        return UIBarButtonItem(
            image: UIImage(systemName: "line.3.horizontal.decrease.circle"),
            menu: filterMenu
        )
    }

    var newestAction: UIAction {
        UIAction(
            title: "Newest",
            state: orderBy == .newest ? .on : .off,
            handler: { [weak self] action in
                self?.orderBy = .newest
                self?.setRightBarButtonItems(animated: false)
            }
        )
    }

    var oldestAction: UIAction {
        UIAction(
            title: "Oldest",
            state: orderBy == .oldest ? .on : .off,
            handler: { [weak self] action in
                self?.orderBy = .oldest
                self?.setRightBarButtonItems(animated: false)
            }
        )
    }

    var nameAction: UIAction {
        UIAction(
            title: "Name",
            image: UIImage(systemName: "textformat.abc.dottedunderline"),
            state: orderBy == .name ? .on : .off,
            handler: { [weak self] action in
                self?.orderBy = .name
                self?.setRightBarButtonItems(animated: false)
            }
        )
    }

    var lastUpdatedAction: UIAction {
        UIAction(
            title: "Recent",
            image: UIImage(systemName: "clock"),
            state: orderBy == .lastUpdated ? .on : .off,
            handler: { [weak self] action in
                self?.orderBy = .lastUpdated
                self?.setRightBarButtonItems(animated: false)
            }
        )
    }

    var filterMenu: UIMenu {
        let dateMenu = UIMenu(title: "Date", image: UIImage(systemName: "calendar"), children: [
            newestAction,
            oldestAction,
        ])

        let menu = UIMenu(title: "", children: [
            nameAction,
            lastUpdatedAction,
            dateMenu,
        ])

        return menu
    }

    var showEmptinessView: Bool = false {
        didSet {
            if showEmptinessView {
                if !oldValue {
                    searchController.searchBar.isHidden = showEmptinessView
                    tableview.backgroundView = EmptinessView()
                }
            } else {
                tableview.backgroundView = nil
                searchController.searchBar.isHidden = false
            }
        }
    }

    private lazy var searchController: UISearchController = {
        let searchController = UISearchController()
        return searchController
    }()

    // MARK: - DataSource
    
    lazy var datasource: UITableViewDiffableDataSource<Int, String> = {
        let datasource = UITableViewDiffableDataSource<Int, String>(tableView: tableview) { [unowned self] tableview, indexPath, uuidString in
            guard let link = try? self.account.fetchLink(with: uuidString) else {
                fatalError("Error fetching single link to represent in LinksTableViewController, this should not happen.")
            }
            
            let cell = tableview.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! LinkCell
            cell.link = link
            cell.action = { [unowned self] in self.presentFloatingInfoViewController(for: link) }
            cell.layoutIfNeeded()
            return cell
        }
        
        return datasource
    }()
    
    // MARK: - General Setup

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .never

        navigationItem.searchController = searchController
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search"
        searchController.searchBar.delegate = self
        
        setRightBarButtonItems(animated: false)
        
        view.backgroundColor = .systemBackground
        
        tableview.delegate = self
        tableview.prefetchDataSource = self

        NotificationCenter.default.addObserver(self, selector: #selector(didDeleteNotification(_:)), name: .UserDidDeleteLink, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didUpdateNotification(_:)), name: .UserDidUpdateLink, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didInsertNotification(_:)), name: .UserDidAddLink, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didUpdateImageNotification(_:)), name: .DidUpdateImage, object: nil)

        view.addSubview(tableview)
        loadLinks()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableview.frame = view.bounds
    }
    
    private func loadLinks() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, String>()
        
        snapshot.appendSections([0])
        
        guard let category = category else { return }
        
        var uuids: [String]? = nil
        switch category {
        case .all:
            guard let res = try? account.fetchAllLinkIDs(order: orderBy) else { return }
            uuids = res
        case .unread:
            guard let res = try? account.fetchUnreadLinkIDs(order: orderBy) else { return }
            uuids = res
        case .starred:
            guard let res = try? account.fetchStarredLinkIDs(order: orderBy) else { return }
            uuids = res
        case .archived:
            guard let res = try? account.fetchArchivedLinkIDs(order: orderBy) else { return }
            uuids = res
        case .group(let group):
            guard let res = try? account.fetchLinkIDs(in: group, order: orderBy) else { return }
            uuids = res
        case .tag(let tag):
            guard let res = try? account.fetchLinkIDs(in: tag, order: orderBy) else { return }
            uuids = res
        }
        
        if let uuids = uuids {
            snapshot.appendItems(uuids, toSection: 0)
        }

        if snapshotCache == nil {
            snapshotCache = snapshot
        }

        showEmptinessView = snapshot.numberOfItems == 0
        datasource.apply(snapshot, animatingDifferences: true)
    }
    
    // MARK: - Data managment

    private func onReloadPressed(link: Links.Link) {
        Task.init {
            await account.reload(link)
        }
    }
    
    private func onDeletePressed(link: Links.Link) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            Task.init {
                await self.account.delete(link: link)
            }
        }
    }
    
    private func onStarPressed(link: Links.Link) {
        link.starred = !link.starred
        Task.init {
            await account.update(link: link)
        }
    }
    
    private func onReadPressed(link: Links.Link) {
        link.unread = !link.unread
        Task.init {
            await account.update(link: link)
        }
    }

    private func onSharePressed(link: Links.Link, sourceRect: CGRect) {
        let linkActivity = LinkActivity(link, imageProvider: ImageStorage.shared)
        let activityController = UIActivityViewController(activityItems: [linkActivity], applicationActivities: nil)
        activityController.popoverPresentationController?.sourceView = tableview
        activityController.popoverPresentationController?.sourceRect = sourceRect
        present(activityController, animated: true, completion: nil)
    }
    
    // MARK: - ViewControllers Presentations
    
    private func onEditPressed(link: Links.Link) {
        let view = AddLinkViewController()
        view.account = account
        view.configuration = .edit(link)
        
        let vc = UINavigationController(rootViewController: view)
        present(vc, animated: true)
    }

    private func onArchivePressed(link: Links.Link) {
        link.archived = !link.archived
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            Task.init {
                await self.account.update(link: link)
            }
        }
    }

    private func presentFloatingInfoViewController(for link: Links.Link) {
        let lv = LinkDetailView(link: link)

        if let searchIsActive = navigationItem.searchController?.isActive, searchIsActive {
            self.dismiss(animated: true)
        }

        let hc = UIHostingController(rootView: lv)
        hc.modalPresentationStyle = .overFullScreen
        hc.view.backgroundColor = .clear
        present(hc, animated: true, completion: {
            UIView.animate(withDuration: 0.1) {
                hc.view.backgroundColor = UIColor.black.withAlphaComponent(UITraitCollection.current.userInterfaceStyle == .dark ? 0.5 : 0.1)
            }
        })
    }
    
    private func open(_ link: Links.Link) {
        guard let url = URLRedirector().redirect(link) else { return }

        Task {
            await AppReviewManager().registerReviewWorthyAction()
        }

        if UserDefaultsWrapper().get(key: .openInApp) {
            let configuration = SFSafariViewController.Configuration()
            configuration.entersReaderIfAvailable = UserDefaultsWrapper().get(key: DefaultsKey.readMode)
            configuration.barCollapsingEnabled = true
            
            let safari = SFSafariViewController(url: url, configuration: configuration)
            safari.modalPresentationStyle = .overFullScreen
            present(safari, animated: true, completion: nil)
        } else {
            UIApplication.shared.open(url)
        }

        if link.unread, UserDefaultsWrapper().get(key: .markReadOnOpen) {
            link.unread = false
            Task.init {
                await account.update(link: link)
            }
        }
    }
}

extension LinksTableViewController: UITableViewDelegate {
    
    // MARK: - Row Selection

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard
            let uuid = datasource.itemIdentifier(for: indexPath),
            let link = try? self.account.fetchLink(with: uuid)
        else { return }
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        open(link)
    }
    
    // MARK: - Swipe Actions
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard
            let uuid = datasource.itemIdentifier(for: indexPath),
            let link = try? self.account.fetchLink(with: uuid)
        else { return nil }

        let edit: UIContextualAction = {
            let edit = UIContextualAction(style: .normal, title: nil) { [weak self] (action, view, completionHandler) in
                self?.onEditPressed(link: link)
                completionHandler(true)
            }
            edit.image = UIImage(systemName: "square.and.pencil")
            edit.backgroundColor = .systemGray4
            return edit
        }()
        
        let trash: UIContextualAction = {
            let trash = UIContextualAction(style: .destructive, title: nil) { [weak self] (action, view, completionHandler) in
                self?.onDeletePressed(link: link)
                completionHandler(true)
            }
            trash.image = UIImage(systemName: "trash")
            trash.backgroundColor = .systemRed
            return trash
        }()

        return UISwipeActionsConfiguration(actions: [trash, edit])
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard
            let uuid = datasource.itemIdentifier(for: indexPath),
            let link = try? self.account.fetchLink(with: uuid)
        else { return nil }

        let star: UIContextualAction = {
            let star = UIContextualAction(style: .normal, title: nil) { [weak self] (action, view, completionHandler) in
                self?.onStarPressed(link: link)
                completionHandler(true)
            }
            star.image = UIImage(systemName: link.starred ? "star.fill" : "star")
            star.backgroundColor = .systemYellow
            return star
        }()

        let read: UIContextualAction = {
            let read = UIContextualAction(style: .normal, title: nil) { [weak self] (action, view, completionHandler) in
                self?.onReadPressed(link: link)
                completionHandler(true)
            }
            read.image = UIImage(systemName: link.unread ? "circle" : "circle.fill")
            read.backgroundColor = .systemBlue
            return read
        }()

        let archived: UIContextualAction = {
            let archived = UIContextualAction(style: .normal, title: nil) { [weak self] (action, view, completionHandler) in
                self?.onArchivePressed(link: link)
                completionHandler(true)
            }
            archived.image = UIImage(systemName: link.archived ? "tray.and.arrow.up" : "tray")
            archived.backgroundColor = .lightGray
            return archived
        }()

        return UISwipeActionsConfiguration(actions: [star, read, archived])
    }
    
    // MARK: - Long press Context Menus
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard
            let uuid = datasource.itemIdentifier(for: indexPath),
            let link = try? self.account.fetchLink(with: uuid)
        else { return nil }
        
        let identifier = "\(indexPath.row)" as NSString
        return UIContextMenuConfiguration(identifier: identifier, previewProvider: nil) { [unowned self] _ in
            let shareAction = UIAction(title: "Share", image: UIImage(systemName: "square.and.arrow.up")) { [unowned self] _ in
                guard let cell = tableView.cellForRow(at: indexPath) as? LinkCell else { return }

                let rect = cell.convert(cell.contentView.frame, to: tableView)
                self.onSharePressed(link: link, sourceRect: rect)
            }
            
            let editAction = UIAction(title: "Edit", image: UIImage(systemName: "square.and.pencil")) { [unowned self] _ in
                self.onEditPressed(link: link)
            }
            
            let infoAction = UIAction(title: "Info", image: UIImage(systemName: "info.circle")) { [unowned self] _ in
                self.presentFloatingInfoViewController(for: link)
            }
            
            let reloadAction = UIAction(title: "Reload", image: UIImage(systemName: "arrow.clockwise.circle")) { [unowned self] _ in
                self.onReloadPressed(link: link)
            }
            
            let deleteMenu = UIMenu(title: "", options: .displayInline, children: [
                UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { [unowned self] _ in
                    self.onDeletePressed(link: link)
                }
            ])
            
            return UIMenu(title: "", children: [infoAction, editAction, shareAction, reloadAction, deleteMenu])
        }
    }
    
    // MARK: - TableView Editing
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableview.setEditing(editing, animated: animated)
        setRightBarButtonItems(animated: false)
    }
    
    private func setRightBarButtonItems(animated: Bool) {
        var barButtonItems = [editButtonItem]
        if !isEditing {
            barButtonItems.append(filterButton)
        }
        
        navigationItem.setRightBarButtonItems(barButtonItems, animated: animated)
    }
}

extension LinksTableViewController: Logging {
    @objc func didUpdateImageNotification(_ notification: Notification) {
        guard let linkId = notification.userInfo?["imageId"] as? String else { return }

        var snapshot = datasource.snapshot()
        guard snapshot.indexOfItem(linkId) != nil else { return }
        snapshot.reconfigureItems([linkId])

        DispatchQueue.main.async {
            self.datasource.apply(snapshot, animatingDifferences: true)
        }
    }

    @objc func didUpdateNotification(_ notification: Notification) {
        guard let link = notification.userInfo?["link"] as? Links.Link else { return }

        // Links need to be removed from
        //   1. Every category when they have been archived
        //   2. Archived category when they have been un-archived
        if (category != .archived && link.archived) || (category == .archived && !link.archived) {
            removeFromTable(links: [link])
        } else {
            var snapshot = datasource.snapshot()
            // This is not going to call `prepareForReuse` of the cell
            snapshot.reconfigureItems([link.id.uuidString])
            datasource.apply(snapshot, animatingDifferences: false)
        }
    }

    @objc func didInsertNotification(_ notification: Notification) {
        guard let link = notification.userInfo?["link"] as? Links.Link else { return }

        var snapshot = datasource.snapshot()
        if let firstItem = snapshot.itemIdentifiers.first {
            snapshot.insertItems([link.id.uuidString], beforeItem: firstItem)
        } else {
            snapshot.appendItems([link.id.uuidString])
        }
        datasource.apply(snapshot, animatingDifferences: true)
        showEmptinessView = snapshot.numberOfItems == 0
    }

    @objc func didDeleteNotification(_ notification: Notification) {
        guard let link = notification.userInfo?["link"] as? Links.Link else { return }
        removeFromTable(links: [link])
    }

    private func removeFromTable(links: [Links.Link]) {
        var snapshot = datasource.snapshot()
        snapshot.deleteItems(links.map { $0.id.uuidString })
        datasource.apply(snapshot, animatingDifferences: true)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.showEmptinessView = snapshot.numberOfItems == 0
        }
    }
}

import os
extension LinksTableViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            showEmptinessView = snapshotCache.numberOfItems == 0
            datasource.apply(snapshotCache, animatingDifferences: true)
            return
        }

        guard var snapshot = snapshotCache else { return }
        guard let uuids: [String] = try? account.fetchLinkIDs(matching: searchText) else { return }

        let filterSet = Set(uuids)
        var toRemove = [String]()
        for uuid in snapshot.itemIdentifiers {
            if !filterSet.contains(uuid) {
                toRemove.append(uuid)
            }
        }

        snapshot.deleteItems(toRemove)

        showEmptinessView = snapshot.numberOfItems == 0
        datasource.apply(snapshot, animatingDifferences: true)
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        os_log(.debug, "invalidating search and reloading unfiltered snapshot")
        showEmptinessView = snapshotCache.numberOfItems == 0
        datasource.apply(snapshotCache, animatingDifferences: true)
    }
}

extension LinksTableViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        let ids = indexPaths.compactMap({ datasource.itemIdentifier(for: $0) })
        for id in ids {
            ImageStorage.shared.loadImageInCacheWithUIGraphicsContext(for: id)
        }
    }
}
