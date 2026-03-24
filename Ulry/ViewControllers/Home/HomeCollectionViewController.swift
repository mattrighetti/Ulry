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
import SwiftUI
import Combine
import LinksMetadata

enum HomeCollectionViewSection: String {
    case main
    case groups
}

class HomeCollectionView: UIViewController {
    var queueActivitySubscriber = Set<AnyCancellable>()

    var account: Account = {
        let account = Account(dataFolder: Paths.dataFolder.absoluteString, type: .local, accountID: "id", imageCache: ImageStorage.shared)
        return account
    }()

    // MARK: - UI

    lazy var addLinkButton: UIBarButtonItem = {
        UIBarButtonItem(image: UIImage(systemName: "plus.circle"), primaryAction: UIAction { [unowned self] _ in
            self.addLinkPressed()
        })
    }()

    lazy var addGroupButton: UIBarButtonItem = {
        UIBarButtonItem(image: UIImage(systemName: "folder.badge.plus"), primaryAction: UIAction { [unowned self] _ in
            self.addGroupPressed()
        })
    }()

    lazy var addTagButton: UIBarButtonItem = {
        UIBarButtonItem(image: UIImage(systemName: "tag"), primaryAction: UIAction { [unowned self] _ in
            self.addTagPressed()
        })
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

    lazy var statsButton: UIBarButtonItem = {
        UIBarButtonItem(image: UIImage(systemName: "chart.bar"), primaryAction: UIAction { [unowned self] _ in
            let vc = UlryInfoViewController()
            vc.account = account
            navigationController?.pushViewController(vc, animated: true)
        })
    }()

    private let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    lazy var activityIndicator =  UIActivityIndicatorView(style: .medium)

    // MARK: - CollectionView & Layout

    lazy var collectionView: UICollectionViewCustomBackground = {
        let layout = UICollectionViewCompositionalLayout(sectionProvider: sectionProvider)
        let cv = UICollectionViewCustomBackground(frame: .zero, collectionViewLayout: layout)
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

        let headerRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewCell>(elementKind: UICollectionView.elementKindSectionHeader) { supplementaryView, _, indexPath in
            var config = UIListContentConfiguration.groupedHeader()
            config.text = "Groups"
            config.textProperties.font = UIFont.rounded(ofSize: 17, weight: .bold)
            config.textProperties.color = .label
            config.directionalLayoutMargins = .init(top: 0, leading: 0, bottom: 0, trailing: 0)
            supplementaryView.contentConfiguration = config
        }

        var datasource = UICollectionViewDiffableDataSource<HomeCollectionViewSection, Category>(collectionView: collectionView) { collectionView, indexPath, category in
            switch indexPath.section {
            case 1:
                return collectionView.dequeueConfiguredReusableCell(using: groupSectionCellRegistration, for: indexPath, item: category)
            default:
                return collectionView.dequeueConfiguredReusableCell(using: mainSectionCellRegistration, for: indexPath, item: category)
            }
        }

        datasource.supplementaryViewProvider = { collectionView, kind, indexPath -> UICollectionReusableView? in
            guard indexPath.section == 1, kind == UICollectionView.elementKindSectionHeader else { return nil }
            return collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
        }

        return datasource
    }()

    // MARK: - View Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(didUpdateGroup(_:)), name: .UserDidUpdateGroup, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didAddGroup(_:)), name: .UserDidAddGroup, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didDeleteGroup(_:)), name: .UserDidDeleteGroup, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showFetching), name: .AccountIsFetching, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(stopFetching), name: .AccountIsNotFetching, object: nil)

        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.isToolbarHidden = true
        navigationItem.title = "Home"

        navigationItem.rightBarButtonItems = [addLinkButton, .fixedSpace(8), addGroupButton, addTagButton]
        navigationItem.leftBarButtonItems = [settingsButton, statsButton]

        view.addSubview(collectionView)
        collectionView.delegate = self

        setupDatasource()
        if !showOnboardingIfFirstLaunch() {
            showWhatsNewIfNewVersion()
        }
        appReviewLogic()
    }

    private func appReviewLogic() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(2e9))
            guard let count = try? await account.fetchAllLinkIDs(order: .lastUpdated).count else { return }
            if count > 10 &&  navigationController?.topViewController is HomeCollectionView {
                await AppReviewManager().requestReviewIfAppropriate(in: view)
            }
        }
    }

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
        navigationItem.rightBarButtonItems = [addLinkButton, .fixedSpace(8), addGroupButton, addTagButton, UIBarButtonItem(customView: activityIndicator)]
    }

    @objc private func stopFetching() {
        activityIndicator.stopAnimating()
        navigationItem.rightBarButtonItems = [addLinkButton, .fixedSpace(8), addGroupButton, addTagButton]
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView.collectionViewLayout.invalidateLayout()
    }

    // MARK: - Setup Data
    private func setupDatasource() {
        var snapshot = NSDiffableDataSourceSnapshot<HomeCollectionViewSection, Category>()

        snapshot.appendSections([.main])
        snapshot.appendItems([.all, .unread, .starred, .archived], toSection: .main)

        if let groups = try? account.fetchAllGroups(), !groups.isEmpty {
            snapshot.appendSections([.groups])
            snapshot.appendItems(groups.map { .group($0) }, toSection: .groups)
        }

        datasource.apply(snapshot, animatingDifferences: true)
    }

    private func reloadSections() {
        var snapshot = datasource.snapshot()
        snapshot.reloadSections([.main, .groups])
        datasource.apply(snapshot, animatingDifferences: false)
    }

    private func addLinkPressed() {
        let view = AddLinkView(account: account)
        let vc = UIHostingController(rootView: view)
        present(vc, animated: true)
    }

    private func addGroupPressed() {
        let view = AddCategoryView(account: account, configuration: .group)
        let vc = UIHostingController(rootView: view)
        present(vc, animated: true)
    }

    private func addTagPressed() {
        let view = AddCategoryView(account: account, configuration: .tag)
        let vc = UIHostingController(rootView: view)
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
        guard case .group(let group) = category else { return }
        let view = AddCategoryView(account: account, configuration: .editGroup(group))
        let vc = UIHostingController(rootView: view)
        present(vc, animated: true)
    }

    private func handleMoveToTrash(category: Category) {
        guard case .group(let group) = category else { return }

        let confirmationAlert = UIAlertController(
            title: "Delete \(group.name)",
            message: "Are you sure you want to delete group \(group.name)?",
            preferredStyle: .alert
        )

        confirmationAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        confirmationAlert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [weak self] _ in
            Task.init {
                await self?.account.delete(group: group)
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
    @objc private func didUpdateGroup(_ notification: Notification) {
        guard notification.userInfo?["group"] is Links.Group else { return }

        var snapshot = datasource.snapshot()

        if snapshot.sectionIdentifiers.contains(.groups) {
            let groups = snapshot.itemIdentifiers(inSection: .groups)
            snapshot.deleteItems(groups)
        }

        if let groups = try? account.fetchAllGroups(), !groups.isEmpty {
            if !snapshot.sectionIdentifiers.contains(.groups) {
                snapshot.appendSections([.groups])
            }
            snapshot.appendItems(groups.map { .group($0) }, toSection: .groups)
        } else if snapshot.sectionIdentifiers.contains(.groups) {
            snapshot.deleteSections([.groups])
        }

        datasource.apply(snapshot, animatingDifferences: true)
    }

    @objc private func didAddGroup(_ notification: Notification) {
        guard notification.userInfo?["group"] is Links.Group else { return }

        var snapshot = datasource.snapshot()

        if snapshot.sectionIdentifiers.contains(.groups) {
            let groups = snapshot.itemIdentifiers(inSection: .groups)
            snapshot.deleteItems(groups)
        }

        if let groups = try? account.fetchAllGroups(), !groups.isEmpty {
            if !snapshot.sectionIdentifiers.contains(.groups) {
                snapshot.appendSections([.groups])
            }
            snapshot.appendItems(groups.map { .group($0) }, toSection: .groups)
        }

        datasource.apply(snapshot, animatingDifferences: true)
    }

    @objc private func didDeleteGroup(_ notification: Notification) {
        guard let group = notification.userInfo!["group"] as? Links.Group else { return }

        var snapshot = datasource.snapshot()
        snapshot.deleteItems([.group(group)])

        // Remove the groups section if no groups remain
        if let remainingGroups = try? account.fetchAllGroups(), remainingGroups.isEmpty {
            snapshot.deleteSections([.groups])
        }

        datasource.apply(snapshot, animatingDifferences: true)
    }
}

