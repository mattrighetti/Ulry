//
//  HomeViewController.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/8/22.
//

import UIKit
import Combine
import SwiftUI

class HomeDiffableDataSource: UITableViewDiffableDataSource<Int, Category> {
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Categories"
        case 1:
            return "Groups"
        case 2:
            return "Tags"
        default:
            return nil
        }
    }
}

fileprivate var categoryColorCell = "CategoryColorCell"
fileprivate var categoryImageCell = "CategoryImageCell"

class HomeViewController: UIViewController {
    let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    lazy var datasource: HomeDiffableDataSource = {
        let datasource = HomeDiffableDataSource(tableView: tableView) { tableView, indexPath, category in
            if indexPath.section == 2 {
                // Tags category
                let cell = tableView.dequeueReusableCell(withIdentifier: categoryColorCell, for: indexPath) as! UIColorCircleTableViewCell
                cell.text = category.rawValue.0
                cell.color = category.rawValue.1
                cell.count = category.rawValue.3
                cell.accessoryType = .disclosureIndicator
                return cell
            } else {
                // Always present/Groups categories
                let cell = tableView.dequeueReusableCell(withIdentifier: categoryImageCell, for: indexPath) as! UIImageCircleTableViewCell
                cell.text = category.rawValue.0
                cell.icon = category.rawValue.2!
                cell.color = category.rawValue.1
                cell.count = category.rawValue.3
                cell.accessoryType = .disclosureIndicator
                return cell
            }
        }
        
        return datasource
    }()
    
    var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.isToolbarHidden = false
        navigationItem.title = "Ulry"
        
        setToolbarItems([
            UIBarButtonItem(title: "Add group", style: .plain, target: self, action: #selector(addGroupPressed)),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
            UIBarButtonItem(title: "Add tag", style: .plain, target: self, action: #selector(addTagPressed))
        ], animated: false)
        
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(image: UIImage(systemName: "plus.circle"), style: .plain, target: self, action: #selector(addLinkPressed))
        ]
        
        tableView.delegate = self
        tableView.register(UIColorCircleTableViewCell.self, forCellReuseIdentifier: categoryColorCell)
        tableView.register(UIImageCircleTableViewCell.self, forCellReuseIdentifier: categoryImageCell)
        tableView.cellLayoutMarginsFollowReadableWidth = true
        
        view.addSubview(tableView)
        
        addCategories()
        
        setupSubscriptions()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Fade the table deselection as the view controller is popped
        if let selectedIndexPath = tableView.indexPathForSelectedRow, let transitionCoordinator = transitionCoordinator {
            transitionCoordinator.animate { context in
                self.tableView.deselectRow(at: selectedIndexPath, animated: true)
            } completion: { context in
                if context.isCancelled {
                    self.tableView.selectRow(at: selectedIndexPath, animated: true, scrollPosition: .none)
                }
            }
        }
    }
    
    private func addCategories() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, Category>()
        
        snapshot.appendSections([0])
        snapshot.appendItems([.all, .unread, .starred], toSection: 0)
        
        snapshot.appendSections([1])
        snapshot.appendItems(GroupStorage.shared.groups.value.map { .group($0) }, toSection: 1)
        
        snapshot.appendSections([2])
        snapshot.appendItems(TagStorage.shared.tags.value.map { .tag($0) }, toSection: 2)
        
        datasource.apply(snapshot, animatingDifferences: false)
    }
    
    private func updateCounts() {
        var newSnapshot = datasource.snapshot()
        let groups: [Category] = GroupStorage.shared.groups.value.map { .group($0) }
        let tags: [Category] = TagStorage.shared.tags.value.map { .tag($0) }
        
        var items: [Category] = [.all, .starred, .unread]
        items.append(contentsOf: groups)
        items.append(contentsOf: tags)
        
        newSnapshot.reloadItems(items)
        datasource.apply(newSnapshot, animatingDifferences: false)
    }
    
    private func updateTags() {
        var newSnapshot = datasource.snapshot()
        let tags: [Category] = TagStorage.shared.tags.value.map { .tag($0) }
        newSnapshot.reloadItems(tags)
        datasource.apply(newSnapshot, animatingDifferences: false)
    }
    
    private func updateGroups() {
        var newSnapshot = datasource.snapshot()
        let groups: [Category] = GroupStorage.shared.groups.value.map { .group($0) }
        newSnapshot.reloadItems(groups)
        datasource.apply(newSnapshot, animatingDifferences: false)
    }
    
    private func setupSubscriptions() {
        LinkStorage.shared.links.eraseToAnyPublisher().sink { [unowned self] _ in
            self.updateCounts()
        }
        .store(in: &cancellables)
        
        GroupStorage.shared.groups.eraseToAnyPublisher().sink { [unowned self] _ in
            self.updateGroups()
        }
        .store(in: &cancellables)
        
        TagStorage.shared.tags.eraseToAnyPublisher().sink { [unowned self] _ in
            self.updateTags()
        }
        .store(in: &cancellables)
    }
    
    @objc private func addLinkPressed() {
        UITextView.appearance().backgroundColor = .clear
        let vc = UIHostingController(rootView: AddLinkView(configuration: .new))
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.large()]
        }
        present(vc, animated: true)
    }
    
    @objc private func addGroupPressed() {
        let vc = UIHostingController(rootView: AddCategoryView(mode: .group))
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.large()]
        }
        present(vc, animated: true)
    }
    
    @objc private func addTagPressed() {
        let vc = UIHostingController(rootView: AddCategoryView(mode: .tag))
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.large()]
        }
        present(vc, animated: true)
    }
    
    private func handleMoveToTrash(category: Category) {
        switch category {
        case .group(let group):
            GroupStorage.shared.delete(group)
        case .tag(let tag):
            TagStorage.shared.delete(tag: tag)
        default:
            return
        }
        
        addCategories()
    }
    
    private func onEditPressed(category: Category) {
        let vc: UIHostingController<AddCategoryView>
        switch category {
        case .group(let group):
            vc = UIHostingController(rootView: AddCategoryView(mode: .editGroup(group)))
        case .tag(let tag):
            vc = UIHostingController(rootView: AddCategoryView(mode: .editTag(tag)))
        default:
            return
        }
        
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.large()]
        }
        present(vc, animated: true)
    }
}

extension HomeViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // The first section is weirdly close to the large navigation title, space that out a bit. This also makes it look better in landscape.
        return section == 0 ? 30.0 : 20.0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 43.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Get category with datasource
        tableView.deselectRow(at: indexPath, animated: true)
        guard let category = datasource.itemIdentifier(for: indexPath) else { return }
        
        // let vc = UIHostingController(rootView: LinkList(filter: category, navigationController: navigationController))
        let vc = LinksTableViewController()
        vc.category = category
        vc.navigationItem.title = category.rawValue.0
        
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard
            let category = datasource.itemIdentifier(for: indexPath),
            category != .all, category != .unread, category != .starred
        else { return nil }
        
        let edit = UIContextualAction(style: .normal, title: "Edit") { [weak self] action, view, completionHandler in
            self?.onEditPressed(category: category)
            completionHandler(true)
        }
        edit.backgroundColor = .systemGray
        
        let trash = UIContextualAction(style: .destructive, title: "Trash") { [weak self] (action, view, completionHandler) in
            self?.handleMoveToTrash(category: category)
            completionHandler(true)
        }
        trash.backgroundColor = .systemRed
        
        return UISwipeActionsConfiguration(actions: [trash, edit])
    }
}
