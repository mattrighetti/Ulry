//
//  LinksTableViewController.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/8/22.
//

import UIKit
import Combine
import SwiftUI

class LinksTableViewController: UIViewController {
    let tableview = UITableView()
    
    var category: Category? {
        didSet {
            guard let category = category else { return }
            switch category {
            case .all:
                links = try! PersistenceController.shared.container.viewContext.fetch(Link.Request.all.rawValue)
            case .starred:
                links = try! PersistenceController.shared.container.viewContext.fetch(Link.Request.starred.rawValue)
            case .unread:
                links = try! PersistenceController.shared.container.viewContext.fetch(Link.Request.unread.rawValue)
            case .tag(let tag):
                links = try! PersistenceController.shared.container.viewContext.fetch(Link.Request.tag(tag).rawValue)
            case .group(let group):
                links = try! PersistenceController.shared.container.viewContext.fetch(Link.Request.folder(group).rawValue)
            }
        }
    }
    
    var links: [Link]?
    var cancellables = Set<AnyCancellable>()
    
    lazy var datasource: UITableViewDiffableDataSource<Int, Link> = {
        let datasource = UITableViewDiffableDataSource<Int, Link>(tableView: tableview) { tableview, indexPath, link in
            let cell = tableview.dequeueReusableCell(withIdentifier: "LinkCell") as! UILinkTableViewCell
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
            return cell
        }
        
        return datasource
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.prefersLargeTitles = true
        
        tableview.delegate = self
        tableview.register(UILinkTableViewCell.self, forCellReuseIdentifier: "LinkCell")
        view.addSubview(tableview)
        
        populateLinks()
        subscribeToLinkChanges()
    }
    
    private func subscribeToLinkChanges() {
        LinkStorage.shared.links.sink { [unowned self] _ in
            // LinkAre updated
            guard let category = self.category else { return }
            switch category {
            case .all:
                self.links = try! PersistenceController.shared.container.viewContext.fetch(Link.Request.all.rawValue)
            case .starred:
                self.links = try! PersistenceController.shared.container.viewContext.fetch(Link.Request.starred.rawValue)
            case .unread:
                self.links = try! PersistenceController.shared.container.viewContext.fetch(Link.Request.unread.rawValue)
            case .tag(let tag):
                self.links = try! PersistenceController.shared.container.viewContext.fetch(Link.Request.tag(tag).rawValue)
            case .group(let group):
                self.links = try! PersistenceController.shared.container.viewContext.fetch(Link.Request.folder(group).rawValue)
            }
            
            populateLinks()
        }.store(in: &cancellables)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableview.frame = view.bounds
        
        if links!.isEmpty {
            pushEmptyLottieView()
        }
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
    
    private func populateLinks() {
        guard let links = links else { return }
        var snapshot = NSDiffableDataSourceSnapshot<Int, Link>()
        snapshot.appendSections([0])
        snapshot.appendItems(links, toSection: 0)
        datasource.apply(snapshot)
    }
    
    private func onEditPressed(link: Link) {
        let vc = UIHostingController(rootView: AddLinkView(configuration: .edit(link)))
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.large()]
        }
        present(vc, animated: true)
    }
    
    private func onDeletePressed(link: Link) {
        LinkStorage.shared.delete(link: link)
    }
    
    private func onStarPressed(link: Link) {
        LinkStorage.shared.toggleStar(link: link)
    }
    
    private func onReadPressed(link: Link) {
        LinkStorage.shared.toggleRead(link: link)
    }
}

extension LinksTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let link = datasource.itemIdentifier(for: indexPath)!
        
        let base = 100.0
        let titleLarge = 15.0
        let titleSmall = 5.0
        let descriptionLarge = 10.0
        let descriptionSmall = 0.0
        
        var sum: CGFloat = base
        if let title = link.ogTitle {
            if title.count > 30 {
                sum += titleLarge
            } else {
                sum += titleSmall
            }
        }
        if let description = link.ogDescription {
            if description.count > 50 {
                sum += descriptionLarge
            } else {
                sum += descriptionSmall
            }
        }
        
        return sum
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let link = datasource.itemIdentifier(for: indexPath) else { return }
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let url = URL(string: link.url) {
            LinkStorage.shared.toggleRead(link: link)
            UIApplication.shared.open(url)
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let link = datasource.itemIdentifier(for: indexPath) else { return nil }
        
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
        guard let link = datasource.itemIdentifier(for: indexPath) else { return nil }
        
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
