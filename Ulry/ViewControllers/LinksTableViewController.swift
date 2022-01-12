//
//  LinksTableViewController.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/8/22.
//

import UIKit
import CoreData
import Combine
import SwiftUI

class LinksTableViewController: UIViewController {
    let context = PersistenceController.shared.container.viewContext
    var coreDataController: NSFetchedResultsController<Link>!
    let tableview = UITableView()
    
    var category: Category? {
        didSet {
            coreDataController =
            NSFetchedResultsController(
                fetchRequest: Link.Request.all.rawValue,
                managedObjectContext: context,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
        }
    }
    
    lazy var datasource: UITableViewDiffableDataSource<Int, NSManagedObjectID> = {
        let datasource = UITableViewDiffableDataSource<Int, NSManagedObjectID>(tableView: tableview) { tableview, indexPath, managedObjectId in
            guard
                let object = try? self.context.existingObject(with: managedObjectId),
                let link = object as? Link
            else {
                fatalError("Managed object does not exist")
            }
            
            let cell = tableview.dequeueReusableCell(withIdentifier: "LinkCell", for: indexPath) as! UILinkTableViewCell
            cell.link = link
            cell.action = { [weak self] in
                let vc = UIHostingController(rootView: LinkDetailView(link: link))
                if let sheet = vc.sheetPresentationController {
                    sheet.detents = [.medium(), .large()]
                    sheet.preferredCornerRadius = 25.0
                    sheet.largestUndimmedDetentIdentifier = .medium
                    sheet.prefersScrollingExpandsWhenScrolledToEdge = false
                    sheet.prefersGrabberVisible = true
                }
                self?.present(vc, animated: true)
            }
            cell.contentView.setNeedsLayout()
            cell.contentView.layoutIfNeeded()
            return cell
        }
        
        return datasource
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.prefersLargeTitles = true
        
        coreDataController.delegate = self
        
        tableview.delegate = self
        tableview.dataSource = datasource
        tableview.register(UILinkTableViewCell.self, forCellReuseIdentifier: "LinkCell")
        tableview.estimatedRowHeight = 200
        tableview.rowHeight = UITableView.automaticDimension
        
        view.addSubview(tableview)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableview.frame = view.bounds
        
        try! coreDataController.performFetch()
    }
    
    private func pushEmptyLottieView() {
        let messageLabel = UILabel()
        messageLabel.text = "Empty"
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        messageLabel.sizeToFit()

        tableview.backgroundView = messageLabel
        tableview.separatorStyle = .none
    }
    
    private func onEditPressed(link: Link) {
        let vc = UIHostingController(rootView: AddLinkView(configuration: .edit(link)))
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.large()]
        }
        present(vc, animated: true)
    }
    
    private func onDeletePressed(link: Link) {
        context.delete(link)
    }
    
    private func onStarPressed(link: Link) {
        link.starred = !link.starred
    }
    
    private func onReadPressed(link: Link) {
        link.unread = !link.unread
    }
}

extension LinksTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard
            let id = datasource.itemIdentifier(for: indexPath),
            let link = try? self.context.existingObject(with: id) as? Link
        else { return }
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let url = URL(string: link.url) {
            LinkStorage.shared.toggleRead(link: link)
            UIApplication.shared.open(url)
        }
    }
    
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
}

extension LinksTableViewController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        guard let datasource = tableview.dataSource as? UITableViewDiffableDataSource<Int, NSManagedObjectID> else {
            assertionFailure("The data source has not implemented snapshot support while it should")
            return
        }
        
        var snapshot = snapshot as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>
        let currentSnapshot = datasource.snapshot() as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>
        
        let reloadIdentifiers: [NSManagedObjectID] = snapshot.itemIdentifiers.compactMap { itemIdentifier in
            guard let currentIndex = currentSnapshot.indexOfItem(itemIdentifier), let index = snapshot.indexOfItem(itemIdentifier), index == currentIndex else {
                return nil
            }
            guard let existingObject = try? controller.managedObjectContext.existingObject(with: itemIdentifier), existingObject.isUpdated else { return nil }
            return itemIdentifier
        }
        snapshot.reloadItems(reloadIdentifiers)
        
        datasource.apply(snapshot as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>, animatingDifferences: true)
    }
}
