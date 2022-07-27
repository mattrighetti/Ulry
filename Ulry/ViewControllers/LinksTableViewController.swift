//
//  LinksTableViewController.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/8/22.
//

import os
import UIKit
import CoreData
import SwiftUI
import SafariServices

private var reuseIdentifier = "LinkCell"

class LinksTableViewController: UIViewController {
    let database = Database.main
    
    lazy var tableview: UITableView = {
        let tableview = UITableView()
        tableview.backgroundColor = .clear
        tableview.register(LinkCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableview.estimatedRowHeight = 200
        tableview.rowHeight = UITableView.automaticDimension
        tableview.translatesAutoresizingMaskIntoConstraints = false
        return tableview
    }()
    
    var category: Category? {
        didSet {
            loadLinks()
        }
    }
    
    var orderBy: OrderBy {
        get {
            let orderByValue = UserDefaults.standard.string(forKey: Defaults.orderBy.rawValue)!
            return OrderBy(rawValue: orderByValue)!
        }
        set {
            UserDefaults.standard.setValue(newValue.rawValue, forKey: Defaults.orderBy.rawValue)
            loadLinks()
        }
    }
    
    // MARK: - Actions
    
    
    // MARK: - DataSource
    
    lazy var datasource: UITableViewDiffableDataSource<Int, String> = {
        let datasource = UITableViewDiffableDataSource<Int, String>(tableView: tableview) { tableview, indexPath, uuidString in
            guard let link = self.database.getLink(with: UUID(uuidString: uuidString)!) else {
                fatalError("Managed object does not exist")
            }
            
            let cell = tableview.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! LinkCell
            cell.link = link
            cell.action = { [weak self] in
                self?.showInfoViewController(for: link)
            }
            
            cell.contentView.setNeedsLayout()
            cell.contentView.layoutIfNeeded()
            return cell
        }
        
        return datasource
    }()
    
    // MARK: - General Setup
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.prefersLargeTitles = true
        
        setRightBarButtonItems(animated: false)
        
        view.backgroundColor = .systemBackground
        
        tableview.delegate = self
        
        view.addSubview(tableview)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableview.frame = view.bounds
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        database.delegate = self
    }
    
    // MARK: - Core Data Requests
    private func orderByName() {
        //coreDataController.fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(Link.ogTitle), ascending: true)]
        
        //try! coreDataController.performFetch()
    }
    
    private func loadLinks() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, String>()
        
        snapshot.appendSections([0])
        
        guard let category = category else { return }
        
        switch category {
        case .all:
            snapshot.appendItems(database.getAllLinksUUID(order: orderBy), toSection: 0)
        case .unread:
            snapshot.appendItems(database.getAllUnreadLinksUUID(order: orderBy), toSection: 0)
        case .starred:
            snapshot.appendItems(database.getAllStarredLinksUUID(order: orderBy), toSection: 0)
        case .group(let group):
            snapshot.appendItems(database.getAllLinksUUID(in: group, order: orderBy), toSection: 0)
        case .tag(let tag):
            snapshot.appendItems(database.getAllLinksUUID(in: tag, order: orderBy), toSection: 0)
        }
        
        datasource.apply(snapshot, animatingDifferences: true)
    }
    
    // MARK: - Data managment
    
    private func onDeletePressed(link: Link) {
        _ = database.delete(link)
    }
    
    private func onStarPressed(link: Link) {
        link.starred = !link.starred
        _ = database.update(link)
    }
    
    private func onReadPressed(link: Link) {
        link.unread = !link.unread
        _ = database.update(link)
    }
    
    // MARK: - ViewControllers Presentations
    
    private func onEditPressed(link: Link) {
        let view = AddLinkViewController()
        view.configuration = .edit(link)
        
        let vc = UINavigationController(rootViewController: view)
        present(vc, animated: true)
    }
    
    private func showInfoViewController(for link: Link) {
        let vc = UIHostingController(rootView: LinkDetailView(link: link))
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.preferredCornerRadius = 25.0
            sheet.largestUndimmedDetentIdentifier = .medium
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
            sheet.prefersGrabberVisible = true
        }
        self.present(vc, animated: true)
    }
}

extension LinksTableViewController: UITableViewDelegate {
    
    // MARK: - Row Selection
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard
            let uuid = datasource.itemIdentifier(for: indexPath),
            let link = database.getLink(with: UUID(uuidString: uuid)!)
        else { return }
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let url = URL(string: link.url) {
            if UserDefaults.standard.value(forKey: Defaults.openInApp.rawValue) as! Bool {
                let configuration = SFSafariViewController.Configuration()
                configuration.entersReaderIfAvailable = UserDefaults.standard.value(forKey: Defaults.readMode.rawValue) as! Bool
                configuration.barCollapsingEnabled = true
                
                let safari = SFSafariViewController(url: url, configuration: configuration)
                safari.modalPresentationStyle = .overFullScreen
                present(safari, animated: true, completion: nil)
            } else {
                UIApplication.shared.open(url)
            }
            
            if UserDefaults.standard.value(forKey: Defaults.markReadOnOpen.rawValue) as! Bool {
                link.unread.toggle()
                _ = database.update(link)
            }
        }
    }
    
    // MARK: - Swipe Actions
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard
            let uuid = datasource.itemIdentifier(for: indexPath),
            let link = database.getLink(with: UUID(uuidString: uuid)!)
        else { return nil }
        
        let edit = UIContextualAction(style: .normal, title: "Edit") { [weak self] action, view, completionHandler in
            self?.onEditPressed(link: link)
            completionHandler(true)
        }
        edit.backgroundColor = .systemGray
        
        let trash = UIContextualAction(style: .destructive, title: "Trash") { [weak self] (action, view, completionHandler) in
            self?.onDeletePressed(link: link)
            completionHandler(true)
        }
        trash.backgroundColor = .systemRed
        
        return UISwipeActionsConfiguration(actions: [trash, edit])
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard
            let uuid = datasource.itemIdentifier(for: indexPath),
            let link = database.getLink(with: UUID(uuidString: uuid)!)
        else { return nil }
        
        let starActionTitle = link.starred ? "Unstar" : "Star"
        let star = UIContextualAction(style: .normal, title: starActionTitle) { [weak self] action, view, completionHandler in
            self?.onStarPressed(link: link)
            completionHandler(true)
        }
        star.backgroundColor = .systemYellow
        
        let readActionTitle = link.unread ? "Read" : "Unread"
        let read = UIContextualAction(style: .destructive, title: readActionTitle) { [weak self] (action, view, completionHandler) in
            self?.onReadPressed(link: link)
            completionHandler(true)
        }
        read.backgroundColor = .systemBlue
        
        return UISwipeActionsConfiguration(actions: [star, read])
    }
    
    // MARK: - Long press Context Menus
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard
            let uuid = datasource.itemIdentifier(for: indexPath),
            let link = database.getLink(with: UUID(uuidString: uuid)!)
        else { return nil }
        
        let identifier = "\(indexPath.row)" as NSString
        return UIContextMenuConfiguration(identifier: identifier, previewProvider: nil) { _ in
            let shareAction = UIAction(title: "Share", image: UIImage(systemName: "square.and.arrow.up")) { _ in
                LinkSharer.share(link: link, in: self)
            }
            
            let editAction = UIAction(title: "Edit", image: UIImage(systemName: "square.and.pencil")) { _ in
                self.onEditPressed(link: link)
            }
            
            let infoAction = UIAction(title: "Info", image: UIImage(systemName: "info.circle")) { _ in
                self.showInfoViewController(for: link)
            }
            
            let reloadAction = UIAction(title: "Reload", image: UIImage(systemName: "arrow.clockwise.circle")) { _ in
                LinkPipeline.main.save(link: link)
            }
            
            let deleteMenu = UIMenu(title: "", options: .displayInline, children: [
                UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
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
        let barButtonItems: [UIBarButtonItem] = {
            if isEditing {
                return [
                    editButtonItem
                ]
            } else {
                return [
                    editButtonItem,
                    UIBarButtonItem(image: UIImage(systemName: "line.3.horizontal.decrease.circle"), menu: createMenu())
                ]
            }
        }()
        
        navigationItem.setRightBarButtonItems(barButtonItems, animated: animated)
    }
    
    private func createMenu() -> UIMenu {
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
        
        let dateMenu = UIMenu(title: "Date", image: UIImage(systemName: "calendar"), children: [
            newestAction,
            oldestAction,
        ])
        
        let menu = UIMenu(title: "Order by", children: [
            nameAction,
            lastUpdatedAction,
            dateMenu,
        ])
        
        return menu
    }
}

extension LinksTableViewController: DatabaseControllerDelegate {
    func databaseController(_ databaseController: Database, didInsert link: Link) {
        DispatchQueue.main.async {
            os_log(.debug, "DID INSERT NOTIFICATION")
            var snapshot = self.datasource.snapshot()
            snapshot.appendItems([link.id.uuidString])
            self.datasource.apply(snapshot, animatingDifferences: true)
        }
    }
    
    func databaseController(_ databaseController: Database, didInsert links: [Link]) {
        DispatchQueue.main.async {
            var snapshot = self.datasource.snapshot()
            snapshot.appendItems(links.map(\.id.uuidString))
            self.datasource.apply(snapshot, animatingDifferences: true)
        }
    }
    
    func databaseController(_ databaseController: Database, didUpdate link: Link) {
        // TODO if I have order by recent and update a link it is not moved to the top
        // maybe I should just recall loadLinks() every time?
        DispatchQueue.main.async {
            var snapshot = self.datasource.snapshot()
            snapshot.reloadItems([link.id.uuidString])
            self.datasource.apply(snapshot, animatingDifferences: true)
        }
    }
    
    func databaseController(_ databaseController: Database, didUpdate links: [Link]) {
        DispatchQueue.main.async {
            var snapshot = self.datasource.snapshot()
            snapshot.reloadItems(links.map(\.id.uuidString))
            self.datasource.apply(snapshot, animatingDifferences: true)
        }
    }
    
    func databaseController(_ databaseController: Database, didDelete link: Link) {
        DispatchQueue.main.async {
            var snapshot = self.datasource.snapshot()
            snapshot.deleteItems([link.id.uuidString])
            self.datasource.apply(snapshot, animatingDifferences: true)
        }
    }
    
    func databaseController(_ databaseController: Database, didDelete links: [Link]) {
        DispatchQueue.main.async {
            var snapshot = self.datasource.snapshot()
            snapshot.deleteItems(links.map(\.id.uuidString))
            self.datasource.apply(snapshot, animatingDifferences: true)
        }
    }
}
