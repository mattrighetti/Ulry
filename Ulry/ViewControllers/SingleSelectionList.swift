//
//  SingleSelectionlist.swift
//  Ulry
//
//  Created by Mattia Righetti on 10/25/22.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import Links
import UIKit
import SwiftUI
import Account

protocol SingleSelectionListDelegate: AnyObject {
    func singleselectionlist(_ singleselectionlist: SingleSelectionList, didSelect group: Links.Group?)
}

    private enum ListItem: Hashable {
        case group(Links.Group)
        case button(String)
    }

class SingleSelectionList: UIViewController {

    var selectedGroup: Links.Group? = nil
    weak var delegate: SingleSelectionListDelegate?

    var account: Account!

    private lazy var collectionview: UICollectionView = {
        let config = UICollectionLayoutListConfiguration(appearance: .grouped)
        let layout = UICollectionViewCompositionalLayout.list(using: config)
        let collectionview = UICollectionView(frame: .zero, collectionViewLayout: layout)

        collectionview.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionview.translatesAutoresizingMaskIntoConstraints = false

        return collectionview
    }()

    private lazy var datasource: UICollectionViewDiffableDataSource<Int, ListItem> = {
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Links.Group> { cell, indexPath, item in
            var config = cell.defaultContentConfiguration()
            config.text = item.name

            if (self.selectedGroup?.id == item.id) {
                let imageview = UIImageView(image: UIImage(systemName: "checkmark.circle.fill")!)
                cell.accessories = [.customView(configuration: .init(customView: imageview, placement: .trailing()))]
            } else {
                cell.accessories = []
            }

            cell.contentConfiguration = config
        }

        let buttonCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, String> { cell, indexPath, item in
            var config = cell.defaultContentConfiguration()
            config.text = item
            cell.accessories = [.disclosureIndicator()]
            cell.contentConfiguration = config
        }

        let datasource = UICollectionViewDiffableDataSource<Int, ListItem>(collectionView: collectionview) { collectionView, indexPath, itemIdentifier in
            switch itemIdentifier {
            case .group(let group):
                return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: group)
            case .button(let title):
                return collectionView.dequeueConfiguredReusableCell(using: buttonCellRegistration, for: indexPath, item: title)
            }
        }

        return datasource
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(setup), name: .UserDidAddGroup, object: nil)

        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.title = "Select group"

        collectionview.delegate = self
        view.addSubview(collectionview)
        
        setup()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionview.frame = view.bounds
    }
    
    @objc private func setup() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, ListItem>()

        snapshot.appendSections([0, 1])

        if let groups = try? account.fetchAllGroups() {
            snapshot.appendItems(groups.map { .group($0) }, toSection: 0)
        }

        snapshot.appendItems([.button("Add new group")], toSection: 1)

        datasource.apply(snapshot, animatingDifferences: false)
    }

    private func reloadItems() {
        var snapshot = datasource.snapshot()
        snapshot.reloadSections([0])
        datasource.apply(snapshot, animatingDifferences: false)
    }
}

extension SingleSelectionList: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = datasource.itemIdentifier(for: indexPath) else { return }

        switch item {
        case .group(let group):
            if (selectedGroup?.id == group.id) {
                selectedGroup = nil
            } else {
                selectedGroup = group
            }

            delegate?.singleselectionlist(self, didSelect: selectedGroup)
            reloadItems()
        case .button:
            let view = AddCategoryView(account: account, configuration: .group)
            let vc = UIHostingController(rootView: view)
            navigationController?.present(vc, animated: true)
        }

        collectionView.deselectItem(at: indexPath, animated: false)
    }
}
