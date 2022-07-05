//
//  HomeViewController.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/8/22.
//

import UIKit
import CoreData
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
    let database = Database.shared
    
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.register(UIColorCircleTableViewCell.self, forCellReuseIdentifier: categoryColorCell)
        tableView.register(UIImageCircleTableViewCell.self, forCellReuseIdentifier: categoryImageCell)
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    lazy var datasource: HomeDiffableDataSource = {
        let datasource = HomeDiffableDataSource(tableView: tableView) { tableView, indexPath, category in
            if indexPath.section == 2 {
                // Tags category
                let cell = tableView.dequeueReusableCell(withIdentifier: categoryColorCell, for: indexPath) as! UIColorCircleTableViewCell
                cell.text = category.cellContent.title
                cell.color = category.cellContent.backgroundColor
                cell.count = category.cellContent.linksCount
                cell.accessoryType = .disclosureIndicator
                cell.contentView.setNeedsLayout()
                cell.contentView.layoutIfNeeded()
                return cell
            } else {
                // Always present/Groups categories
                let cell = tableView.dequeueReusableCell(withIdentifier: categoryImageCell, for: indexPath) as! UIImageCircleTableViewCell
                cell.text = category.cellContent.title
                cell.icon = category.cellContent.icon!
                cell.color = category.cellContent.backgroundColor
                cell.count = category.cellContent.linksCount
                cell.accessoryType = .disclosureIndicator
                cell.contentView.setNeedsLayout()
                cell.contentView.layoutIfNeeded()
                return cell
            }
        }
        
        return datasource
    }()
    
    lazy var addTagButton: UIButton = {
        let imageConfiguration = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
        
        var configuration = UIButton.Configuration.plain()
        configuration.baseForegroundColor = .systemBlue
        configuration.attributedTitle = AttributedString(NSAttributedString(string: "Add tag", attributes: [.font: UIFont.rounded(ofSize: 14, weight: .bold)]))
        configuration.image = UIImage(systemName: "plus.circle.fill", withConfiguration: imageConfiguration)?.withTintColor(.systemBlue)
        configuration.imagePadding = 5.0
        configuration.imagePlacement = .trailing
        
        let button = UIButton(configuration: configuration, primaryAction: UIAction { _ in self.addTagPressed() })
        return button
    }()
    
    lazy var addGroupButton: UIButton = {
        let imageConfiguration = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
        
        var configuration = UIButton.Configuration.plain()
        configuration.baseForegroundColor = .systemTeal
        configuration.attributedTitle = AttributedString(NSAttributedString(string: "Add group", attributes: [.font: UIFont.rounded(ofSize: 14, weight: .bold)]))
        configuration.image = UIImage(systemName: "folder.fill.badge.plus", withConfiguration: imageConfiguration)?.withTintColor(.systemTeal)
        configuration.imagePadding = 7.0
        
        let button = UIButton(configuration: configuration, primaryAction: UIAction { _ in self.addGroupPressed() })
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.isToolbarHidden = false
        navigationItem.title = "Ulry"
        
        setToolbarItems([
            UIBarButtonItem(customView: addGroupButton),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
            UIBarButtonItem(customView: addTagButton)
        ], animated: false)
        
        let addLinkButton = UIBarButtonItem(title: nil, image: UIImage(systemName: "plus.circle"), primaryAction: UIAction { _ in
            let view = UINavigationController(rootViewController: AddLinkViewController())
            self.present(view, animated: true)
        }, menu: nil)
        
        let settingsButton = UIBarButtonItem(title: nil, image: UIImage(systemName: "gearshape"), primaryAction: UIAction { _ in
            let view = UINavigationController(rootViewController: SettingsViewController())
            view.modalPresentationStyle = .fullScreen
            self.present(view, animated: true)
        }, menu: nil)
        
        navigationItem.rightBarButtonItems = [addLinkButton]
        navigationItem.leftBarButtonItems = [settingsButton]
        
        tableView.delegate = self
        
        view.addSubview(tableView)
        addSections()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        database.delegate = self
        reloadSections()
        
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
    
    private func addSections() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, Category>()
        
        snapshot.appendSections([0])
        snapshot.appendItems([.all, .unread, .starred], toSection: 0)
        
        snapshot.appendSections([1])
        snapshot.appendItems(database.getAllGroups().map { .group($0) }, toSection: 1)
        
        snapshot.appendSections([2])
        snapshot.appendItems(database.getAllTags().map { .tag($0) }, toSection: 2)
        
        datasource.apply(snapshot, animatingDifferences: true)
    }
    
    private func reloadSections() {
        // Useful to reload basic data in case underlying data changes
        var snapshot = datasource.snapshot()
        snapshot.reloadSections([0,1,2])
        datasource.apply(snapshot, animatingDifferences: false)
    }
    
    @objc private func addLinkPressed() {
        let vc = AddLinkViewController()
        present(vc, animated: true)
    }
    
    @objc private func addGroupPressed() {
        let view = AddCategoryViewController()
        view.configuration = .group
        let vc = UINavigationController(rootViewController: view)
        present(vc, animated: true)
    }
    
    @objc private func addTagPressed() {
        let view = AddCategoryViewController()
        view.configuration = .tag
        let vc = UINavigationController(rootViewController: view)
        present(vc, animated: true)
    }
    
    private func handleMoveToTrash(category: Category) {
        switch category {
        case .group(let group):
            _ = database.delete(group)
        case .tag(let tag):
            _ = database.delete(tag)
        default:
            return
        }
        
        var snapshot = datasource.snapshot()
        snapshot.deleteItems([category])
        datasource.apply(snapshot, animatingDifferences: true)
    }
    
    private func onEditPressed(category: Category) {
        switch category {
        case .group(let group):
            let view = AddCategoryViewController()
            view.configuration = .editGroup(group)
            let vc = UINavigationController(rootViewController: view)
            present(vc, animated: true)
            
        case .tag(let tag):
            let view = AddCategoryViewController()
            view.configuration = .editTag(tag)
            let vc = UINavigationController(rootViewController: view)
            present(vc, animated: true)
            
        default:
            return
        }
    }
}

// MARK: - UITableViewDelegate

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
        
        let vc = LinksTableViewController()
        vc.category = category
        vc.navigationItem.title = category.cellContent.title
        vc.hidesBottomBarWhenPushed = true
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

extension HomeViewController: DatabaseControllerDelegate {
    func databaseController(_ databaseController: Database, didInsert link: Link) {
        // Maybe reloading every section could be avoidable:
        // What needs change is:
        //   1. Tag that links belong to
        //   2. Group that links belong to
        //   3. All and unread for sure
        //   4. Starred maybe
        reloadSections()
    }
    
    func databaseController(_ databaseController: Database, didInsert tag: Tag) {
        var snapshot = datasource.snapshot()
        snapshot.appendItems([.tag(tag)], toSection: 2)
        datasource.apply(snapshot, animatingDifferences: true)
    }
    
    func databaseController(_ databaseController: Database, didInsert group: Group) {
        var snapshot = datasource.snapshot()
        snapshot.appendItems([.group(group)], toSection: 1)
        datasource.apply(snapshot, animatingDifferences: true)
    }
    
    func databaseController(_ databaseController: Database, didUpdate group: Group) {
        var snapshot = datasource.snapshot()
        snapshot.reloadItems([.group(group)])
        datasource.apply(snapshot, animatingDifferences: true)
    }
    
    func databaseController(_ databaseController: Database, didUpdate tag: Tag) {
        var snapshot = datasource.snapshot()
        snapshot.reloadItems([.tag(tag)])
        datasource.apply(snapshot, animatingDifferences: true)
    }
    
    func databaseController(_ databaseController: Database, didDelete link: Link) {
        // Maybe reloading every section could be avoidable:
        // What needs change is:
        //   1. Tag that links belong to
        //   2. Group that links belong to
        //   3. All and unread for sure
        //   4. Starred maybe
        reloadSections()
    }
    
    func databaseController(_ databaseController: Database, didDelete links: [Link]) {
        // Maybe reloading every section could be avoidable:
        // What needs change is:
        //   1. Tag that links belong to
        //   2. Group that links belong to
        //   3. All and unread for sure
        //   4. Starred maybe
        reloadSections()
    }
    
    func databaseController(_ databaseController: Database, didDelete group: Group) {
        var snapshot = datasource.snapshot()
        snapshot.deleteItems([.group(group)])
        datasource.apply(snapshot, animatingDifferences: true)
    }
    
    func databaseController(_ databaseController: Database, didDelete tag: Tag) {
        var snapshot = datasource.snapshot()
        snapshot.deleteItems([.tag(tag)])
        datasource.apply(snapshot, animatingDifferences: true)
    }
    
}
