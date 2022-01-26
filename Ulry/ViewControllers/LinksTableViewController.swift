//
//  LinksTableViewController.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/8/22.
//

import UIKit
import CoreData
import SwiftUI
import SafariServices

private var reuseIdentifier = "LinkCell"

class LinksTableViewController: UIViewController {
    let context = CoreDataStack.shared.managedContext
    var coreDataController: NSFetchedResultsController<Link>!
    
    lazy var tableview: UITableView = {
        let tableview = UITableView()
        tableview.backgroundColor = .clear
        tableview.register(UILinkTableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableview.estimatedRowHeight = 200
        tableview.rowHeight = UITableView.automaticDimension
        return tableview
    }()
    
    var category: Category? {
        didSet {
            guard let category = category else { return }
            let request = Link.Request(from: category).fetchRequest
            request.sortDescriptors = orderBy.sortDescriptor
            
            coreDataController = NSFetchedResultsController(
                fetchRequest: request,
                managedObjectContext: context,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
        }
    }
    
    var orderBy: OrderBy {
        get {
            let orderByValue = UserDefaults.standard.string(forKey: Defaults.orderBy.rawValue)!
            return OrderBy(rawValue: orderByValue)!
        }
        set {
            UserDefaults.standard.setValue(newValue.rawValue, forKey: Defaults.orderBy.rawValue)
            coreDataController.fetchRequest.sortDescriptors = newValue.sortDescriptor
            try! coreDataController.performFetch()
        }
    }
    
    // MARK: - Actions
    
    
    // MARK: - DataSource
    
    lazy var datasource: UITableViewDiffableDataSource<Int, NSManagedObjectID> = {
        let datasource = UITableViewDiffableDataSource<Int, NSManagedObjectID>(tableView: tableview) { tableview, indexPath, managedObjectId in
            guard
                let object = try? self.context.existingObject(with: managedObjectId),
                let link = object as? Link
            else {
                fatalError("Managed object does not exist")
            }
            
            let cell = tableview.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! UILinkTableViewCell
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
        coreDataController.delegate = self
        
        view.addSubview(tableview)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableview.frame = view.bounds
        
        try! coreDataController.performFetch()
    }
    
    // MARK: - Core Data Requests
    private func orderByName() {
        coreDataController.fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(Link.ogTitle), ascending: true)]
        
        try! coreDataController.performFetch()
    }
    
    // MARK: - Data managment
    
    private func onDeletePressed(link: Link) {
        context.delete(link)
        CoreDataStack.shared.saveContext()
    }
    
    private func onStarPressed(link: Link) {
        link.starred = !link.starred
    }
    
    private func onReadPressed(link: Link) {
        link.unread = !link.unread
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
            let id = datasource.itemIdentifier(for: indexPath),
            let link = try? self.context.existingObject(with: id) as? Link
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
                CoreDataStack.shared.saveContext()
            }
        }
    }
    
    // MARK: - Swipe Actions
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard
            let id = datasource.itemIdentifier(for: indexPath),
            let link = try? self.context.existingObject(with: id) as? Link
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
            let id = datasource.itemIdentifier(for: indexPath),
            let link = try? self.context.existingObject(with: id) as? Link
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
            let id = datasource.itemIdentifier(for: indexPath),
            let link = try? self.context.existingObject(with: id) as? Link
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
            
            let deleteMenu = UIMenu(title: "", options: .displayInline, children: [
                UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                    self.onDeletePressed(link: link)
                }
            ])
            
            return UIMenu(title: "", children: [infoAction, editAction, shareAction, deleteMenu])
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
                title: "Last updated",
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

extension LinksTableViewController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        var snapshot = snapshot as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>
        let currentSnapshot = datasource.snapshot() as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>
        
        let reloadIdentifiers: [NSManagedObjectID] = snapshot.itemIdentifiers.compactMap { itemIdentifier in
            guard let currentIndex = currentSnapshot.indexOfItem(itemIdentifier), let index = snapshot.indexOfItem(itemIdentifier), index == currentIndex else {
                return nil
            }
            guard let existingObject = try? controller.managedObjectContext.existingObject(with: itemIdentifier), existingObject.isUpdated else { return nil }
            return itemIdentifier
        }
        // Reconfigure items that have the same index
        snapshot.reconfigureItems(reloadIdentifiers)
        
        datasource.apply(snapshot as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>, animatingDifferences: true)
    }
}

extension LinksTableViewController {
    enum OrderBy: String {
        case name
        case lastUpdated
        case oldest
        case newest
        
        var sortDescriptor: [NSSortDescriptor] {
            switch self {
            case .name:
                return [NSSortDescriptor(key: #keyPath(Link.ogTitle), ascending: true)]
            case .lastUpdated:
                return [NSSortDescriptor(key: #keyPath(Link.updatedAt), ascending: true)]
            case .newest:
                return [NSSortDescriptor(key: #keyPath(Link.createdAt), ascending: false)]
            case .oldest:
                return [NSSortDescriptor(key: #keyPath(Link.createdAt), ascending: true)]
            }
        }
    }
}
