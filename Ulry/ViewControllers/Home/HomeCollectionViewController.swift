//
//  HomeCollectionViewController.swift
//  Ulry
//
//  Created by Mattia Righetti on 9/24/22.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import Links
import Account
import UIKit
import Combine
import LinksMetadata

enum HomeCollectionViewSection: String {
    case main
    case groups
    case tags
}

class HomeCollectionView: UIViewController {
    var queueActivitySubscriber = Set<AnyCancellable>()

    var account: Account = {
        let account = Account(dataFolder: Paths.dataFolder.absoluteString, type: .local, accountID: "id", imageCache: ImageStorage.shared)
        return account
    }()

    var collapsed: [Bool] {
        get { UserDefaultsWrapper().get(key: .collapsedSections) }
        set { UserDefaultsWrapper().set(newValue, forKey: .collapsedSections) }
    }
    // MARK: - UI

    lazy var addTagButton: UIButton = {
        let imageConfiguration = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
        
        var configuration = UIButton.Configuration.plain()
        configuration.baseForegroundColor = .systemBlue
        configuration.attributedTitle = AttributedString(NSAttributedString(string: "Add tag", attributes: [.font: UIFont.rounded(ofSize: 14, weight: .bold)]))
        configuration.image = UIImage(systemName: "plus.circle.fill", withConfiguration: imageConfiguration)?.withTintColor(.systemBlue)
        configuration.imagePadding = 5.0
        configuration.imagePlacement = .trailing
        
        let button = UIButton(configuration: configuration, primaryAction: UIAction { [unowned self] _ in self.addTagPressed() })
        return button
    }()
    
    lazy var addGroupButton: UIButton = {
        let imageConfiguration = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
        
        var configuration = UIButton.Configuration.plain()
        configuration.baseForegroundColor = .systemTeal
        configuration.attributedTitle = AttributedString(NSAttributedString(string: "Add group", attributes: [.font: UIFont.rounded(ofSize: 14, weight: .bold)]))
        configuration.image = UIImage(systemName: "folder.fill.badge.plus", withConfiguration: imageConfiguration)?.withTintColor(.systemTeal)
        configuration.imagePadding = 7.0
        
        let button = UIButton(configuration: configuration, primaryAction: UIAction { [unowned self] _ in self.addGroupPressed() })
        return button
    }()
    
    lazy var addLinkButton: UIBarButtonItem = {
        return UIBarButtonItem(
            title: nil,
            image: UIImage(systemName: "plus.circle"),
            primaryAction: UIAction { [unowned self] _ in
                self.addLinkPressed()
            },
            menu: nil
        )
    }()

    lazy var settingsButton: UIBarButtonItem = {
        return UIBarButtonItem(
            title: nil,
            image: UIImage(systemName: "gearshape"),
            primaryAction: UIAction { [unowned self] _ in
                let settingsViewController = SettingsViewController()
                settingsViewController.account = account
                let view = UINavigationController(rootViewController: settingsViewController)
                view.modalPresentationStyle = .fullScreen
                self.present(view, animated: true)
            },
            menu: nil
        )
    }()
    
    private let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    lazy var activityIndicator =  UIActivityIndicatorView(style: .medium)

    // MARK: - CollectionView & Layout
    
    lazy var collectionView: UICollectionViewCustomBackground = {
        let layout = UICollectionViewCompositionalLayout(sectionProvider: sectionProvider)
        let cv = UICollectionViewCustomBackground(frame: .zero, collectionViewLayout: layout)
        // This is to make touchBegan of the cell trigger immediately on touch
        cv.delaysContentTouches = false
        cv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return cv
    }()
    
    // MARK: - Data Source
    
    lazy var datasource: UICollectionViewDiffableDataSource<HomeCollectionViewSection, Category> = {
        
        let mainSectionCellRegistration = UICollectionView.CellRegistration<MainCategoryCollectionViewCell, Category> { cell, indexPath, category in
            cell.update(with: category)
        }
        
        let groupSectionCellRegistration = UICollectionView.CellRegistration<GroupCollectionViewCell, Category> { cell, indexPath, category in
            cell.longPressAction = {
                self.prepareLongPressGestureActionSheets(for: indexPath)
            }
            cell.update(with: category)
        }
        
        let tagSectionCellRegistration = UICollectionView.CellRegistration<TagCollectionViewCell, Category> { cell, indexPath, category in
            cell.longPressAction = {
                self.prepareLongPressGestureActionSheets(for: indexPath)
            }
            cell.update(with: category)
        }
        
        let headerRegistration: UICollectionView.SupplementaryRegistration<HomeHeaderCollectionViewCell> = .init(elementKind: UICollectionView.elementKindSectionHeader) { [unowned self] supplementaryView, _, indexPath in
            var config = supplementaryView.defaultContentConfiguration()
            config.textProperties.font = UIFont.rounded(ofSize: 20, weight: .semibold)
            config.textProperties.color = .label

            switch indexPath.section {
            case 0:
                config.text = "Main"
                supplementaryView.section = .main
            case 1:
                config.text = "Groups"
                supplementaryView.section = .groups
            case 2:
                config.text = "Tags"
                supplementaryView.section = .tags
            default:
                fatalError("cannot run header registration for this indexPath: \(indexPath)")
            }

            supplementaryView.isExpanded = self.collapsed[indexPath.section]
            supplementaryView.contentConfiguration = config
            supplementaryView.delegate = self
        }
        
        var datasource = UICollectionViewDiffableDataSource<HomeCollectionViewSection, Category>(collectionView: collectionView) { collectionView, indexPath, category in
            switch indexPath.section {
            case 1:
                return collectionView.dequeueConfiguredReusableCell(using: groupSectionCellRegistration, for: indexPath, item: category)
            case 2:
                return collectionView.dequeueConfiguredReusableCell(using: tagSectionCellRegistration, for: indexPath, item: category)
            default:
                return collectionView.dequeueConfiguredReusableCell(using: mainSectionCellRegistration, for: indexPath, item: category)
            }
        }
        
        datasource.supplementaryViewProvider = { cv, kind, indexPath -> UICollectionReusableView? in
            if indexPath.section == 0 {
                return nil
            }

            if kind == UICollectionView.elementKindSectionHeader {
                return self.collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
            }
            
            return nil
        }
        
        return datasource
    }()
    
    // MARK: - View Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(didUpdateTag(_:)), name: .UserDidUpdateTag, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didUpdateGroup(_:)), name: .UserDidUpdateGroup, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didAddTag(_:)), name: .UserDidAddTag, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didAddGroup(_:)), name: .UserDidAddGroup, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didDeleteTag(_:)), name: .UserDidDeleteTag, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didDeleteGroup(_:)), name: .UserDidDeleteGroup, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showFetching), name: .AccountIsFetching, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(stopFetching), name: .AccountIsNotFetching, object: nil)

        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.isToolbarHidden = false
        navigationItem.title = "Home"

        setToolbarItems([
            UIBarButtonItem(customView: addGroupButton),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
            UIBarButtonItem(customView: activityIndicator),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
            UIBarButtonItem(customView: addTagButton)
        ], animated: false)
                
        navigationItem.rightBarButtonItems = [addLinkButton]
        navigationItem.leftBarButtonItems = [settingsButton]
        
        view.addSubview(collectionView)
        collectionView.delegate = self
        
        setupDatasource()
        if !showOnboardingIfFirstLaunch() {
            showWhatsNewIfNewVersion()
        }
        appReviewLogic()
    }

    /// Triggers app review if three conditions hold:
    ///   1. There are at least 10 links saved in the database
    ///   2. HomeCollectionView is being presented (at the top of the navigation controller)
    ///   3. All of the above after waiting 2 seconds
    private func appReviewLogic() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(2e9))
            guard let count = try? await account.fetchAllLinkIDs(order: .lastUpdated).count else { return }
            if count > 10 &&  navigationController?.topViewController is HomeCollectionView {
                await AppReviewManager().requestReviewIfAppropriate(in: view)
            }
        }
    }

    /// Launches onboarding view in case user launches app for the first time
    private func showOnboardingIfFirstLaunch() -> Bool {
        if UserDefaultsWrapper().get(key: .isFirstLaunch) {
            present(OnboardingView(), animated: true)
            UserDefaultsWrapper().set(false, forKey: .isFirstLaunch)
            UserDefaultsWrapper().set(AppData.appVersion, forKey: .lastShownWhatsNew)
            return true
        }
        return false
    }

    private func showWhatsNewIfNewVersion() {
        let lastShownWhatsNew: String = UserDefaultsWrapper().get(key: .lastShownWhatsNew) ?? ""
        if lastShownWhatsNew == AppData.appVersion {
            return
        }

        present(ChangelogViewController(), animated: true)
        UserDefaultsWrapper().set(AppData.appVersion, forKey: .lastShownWhatsNew)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.frame = view.bounds
    }
    
    @objc private func showFetching() {
        activityIndicator.startAnimating()
    }

    @objc private func stopFetching() {
        activityIndicator.stopAnimating()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    // MARK: - Setup Data
    private func setupDatasource() {
        var snapshot = NSDiffableDataSourceSnapshot<HomeCollectionViewSection, Category>()
        
        snapshot.appendSections([.main, .groups, .tags])
        snapshot.appendItems([.all, .unread, .starred, .archived], toSection: .main)

        if !collapsed[1], let groups = try? account.fetchAllGroups() {
            snapshot.appendItems(groups.map { .group($0) }, toSection: .groups)
        }
        
        if !collapsed[2], let tags = try? account.fetchAllTags() {
            snapshot.appendItems(tags.map { .tag($0) }, toSection: .tags)
        }
        
        datasource.apply(snapshot, animatingDifferences: true)
    }
    
    private func reloadSections() {
        // Useful to reload basic data in case underlying data changes
        var snapshot = datasource.snapshot()
        snapshot.reloadSections([.main,.groups,.tags])
        datasource.apply(snapshot, animatingDifferences: false)
    }
    
    private func addLinkPressed() {
        let view = AddLinkViewController()
        view.account = account
        present(UINavigationController(rootViewController: view), animated: true)
    }
    
    private func addGroupPressed() {
        let view = AddCategoryViewController()
        view.account = account
        view.configuration = .group
        let vc = UINavigationController(rootViewController: view)
        present(vc, animated: true)
    }
    
    private func addTagPressed() {
        let view = AddCategoryViewController()
        view.account = account
        view.configuration = .tag
        let vc = UINavigationController(rootViewController: view)
        present(vc, animated: true)
    }
    
    @objc private func longPressGesture(gesture : UILongPressGestureRecognizer!) {
        guard gesture.state == .began else { return }
        
        let position = gesture.location(in: collectionView)
        if let indexPath = collectionView.indexPathForItem(at: position) {
            guard indexPath.section != 0 else { return }
            prepareLongPressGestureActionSheets(for: indexPath)
        }
    }
    
    private func showEdit(category: Category) {
        let view = AddCategoryViewController()
        view.account = account
        
        switch category {
        case .group(let group):
            view.configuration = .editGroup(group)
        case .tag(let tag):
            view.configuration = .editTag(tag)
        default:
            return
        }
        
        let vc = UINavigationController(rootViewController: view)
        present(vc, animated: true)
    }
    
    private func handleMoveToTrash(category: Category) {
        var confirmationAlertTitle = "Delete "
        var confirmationAlertMessage = "Are you sure you want to delete "
        if case .group(let group) = category {
            confirmationAlertTitle += group.name
            confirmationAlertMessage += "group \(group.name)?"
        } else if case .tag(let tag) = category {
            confirmationAlertTitle += tag.name
            confirmationAlertMessage += "tag \(tag.name)?"
        }

        let confirmationAlert = UIAlertController(
            title: confirmationAlertTitle,
            message: confirmationAlertMessage,
            preferredStyle: .alert
        )

        confirmationAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        confirmationAlert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [weak self] _ in
            switch category {
            case .group(let group):
                Task.init {
                    await self?.account.delete(group: group)
                }
            case .tag(let tag):
                Task.init {
                    await self?.account.delete(tag: tag)
                }
            default:
                return
            }
        }))

        present(confirmationAlert, animated: true)
    }
    
    private func prepareLongPressGestureActionSheets(for indexPath: IndexPath) {
        guard
            let button = collectionView.cellForItem(at: indexPath)?.contentView,
            let category = datasource.itemIdentifier(for: indexPath)
        else {
            return
        }

        let editAction = UIAlertAction(title: "Edit", style: .default) { [weak self] action in
            self?.impactFeedbackGenerator.impactOccurred()
            self?.showEdit(category: category)
        }
        
        let delete = UIAlertAction(title: "Delete", style: .destructive) { [weak self] action in
            self?.impactFeedbackGenerator.impactOccurred()
            self?.handleMoveToTrash(category: category)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.modalPresentationStyle = .popover
        alertController.addAction(editAction)
        alertController.addAction(delete)
        alertController.addAction(cancel)
        
        if let presenter = alertController.popoverPresentationController {
            presenter.sourceView = button
            presenter.sourceRect = button.bounds
        }
        
        impactFeedbackGenerator.impactOccurred()
        present(alertController, animated: true)
    }
}

// MARK: - HomeCollectionViewController Delegate
extension HomeCollectionView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Get category with datasource
        collectionView.deselectItem(at: indexPath, animated: true)
        guard let category = datasource.itemIdentifier(for: indexPath) else { return }
        
        let vc = LinksTableViewController()
        vc.account = account
        vc.category = category
        vc.navigationItem.titleView = CategoryTitleView.getView(for: category)
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension HomeCollectionView {
    @objc private func didUpdateTag(_ notification: Notification) {
        guard !collapsed[2], let tag = notification.userInfo?["tag"] as? Tag else { return }

        var snapshot = datasource.snapshot()

        let tags = snapshot.itemIdentifiers(inSection: .tags)
        snapshot.deleteItems(tags)

        if let tags = try? account.fetchAllTags() {
            snapshot.appendItems(tags.map { .tag($0) }, toSection: .tags)
        }

        snapshot.reconfigureItems([.tag(tag)])

        datasource.apply(snapshot, animatingDifferences: true)
    }

    @objc private func didUpdateGroup(_ notification: Notification) {
        guard !collapsed[1], let group = notification.userInfo?["group"] as? Group else { return }

        var snapshot = datasource.snapshot()

        let groups = snapshot.itemIdentifiers(inSection: .groups)
        snapshot.deleteItems(groups)

        if let groups = try? account.fetchAllGroups() {
            snapshot.appendItems(groups.map { .group($0) }, toSection: .groups)
        }

        snapshot.reconfigureItems([.group(group)])

        datasource.apply(snapshot, animatingDifferences: true)
    }

    @objc private func didAddTag(_ notification: Notification) {
        guard !collapsed[2], let tag = notification.userInfo?["tag"] as? Tag else { return }

        var snapshot = datasource.snapshot()

        let tags = snapshot.itemIdentifiers(inSection: .tags)
        snapshot.deleteItems(tags)

        if let tags = try? account.fetchAllTags() {
            snapshot.appendItems(tags.map { .tag($0) }, toSection: .tags)
        }

        snapshot.reconfigureItems([.tag(tag)])

        datasource.apply(snapshot, animatingDifferences: true)
    }

    @objc private func didAddGroup(_ notification: Notification) {
        guard !collapsed[1], let group = notification.userInfo?["group"] as? Group else { return }

        var snapshot = datasource.snapshot()

        let groups = snapshot.itemIdentifiers(inSection: .groups)
        snapshot.deleteItems(groups)

        if let groups = try? account.fetchAllGroups() {
            snapshot.appendItems(groups.map { .group($0) }, toSection: .groups)
        }

        snapshot.reconfigureItems([.group(group)])

        datasource.apply(snapshot, animatingDifferences: true)
    }

    @objc private func didDeleteTag(_ notification: Notification) {
        guard !collapsed[2], let tag = notification.userInfo!["tag"] as? Tag else { return }

        var snapshot = datasource.snapshot()
        snapshot.deleteItems([.tag(tag)])
        datasource.apply(snapshot, animatingDifferences: true)
    }

    @objc private func didDeleteGroup(_ notification: Notification) {
        guard !collapsed[1], let group = notification.userInfo!["group"] as? Group else { return }

        var snapshot = datasource.snapshot()
        snapshot.deleteItems([.group(group)])
        datasource.apply(snapshot, animatingDifferences: true)
    }
}

extension HomeCollectionView: HomeHeaderCollectionViewCellDelegate {
    func toggle(section: HomeCollectionViewSection) {
        let index: Int!
        switch section {
        case .groups:
            index = 1
        case .tags:
            index = 2
        default:
            fatalError()
        }

        collapsed[index] ? expand(section) : collapse(section)
        collapsed[index] = !collapsed[index]
    }

    private func collapse(_ section: HomeCollectionViewSection) {
        var snapshot = datasource.snapshot()
        snapshot.deleteItems(snapshot.itemIdentifiers(inSection: section))
        datasource.apply(snapshot, animatingDifferences: true)
    }

    private func expand(_ section: HomeCollectionViewSection) {
        var snapshot = datasource.snapshot()

        switch section {
        case .groups:
            if let groups = try? account.fetchAllGroups() {
                snapshot.appendItems(groups.map { .group($0) }, toSection: .groups)
            }
        case .tags:
            if let tags = try? account.fetchAllTags() {
                snapshot.appendItems(tags.map { .tag($0) }, toSection: .tags)
            }
        default:
            fatalError()
        }

        datasource.apply(snapshot, animatingDifferences: true)
    }
}
