//
//  MSList.swift
//  Ulry
//
//  Created by Mattia Righetti on 10/24/22.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import Links
import UIKit
import SwiftUI
import Account

protocol MultipleSelectionListDelegate: AnyObject {
    func multipleselectionlist(_ multipleselectionlist: MultipleSelectionList, didUpdateSelectedTags tags: [Tag])
}

    private enum ListItem: Hashable {
        case tag(Tag)
        case button(String)
    }

class MultipleSelectionList: UIViewController {
    var account: Account!

    var selectedTags = Set<Tag>()
    weak var delegate: MultipleSelectionListDelegate?

    private lazy var collectionview: UICollectionView = {
        let config = UICollectionLayoutListConfiguration(appearance: .grouped)
        let layout = UICollectionViewCompositionalLayout.list(using: config)
        let collectionview = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionview.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionview.translatesAutoresizingMaskIntoConstraints = false
        return collectionview
    }()

    private lazy var datasource: UICollectionViewDiffableDataSource<Int, ListItem> = {
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Tag> { cell, indexPath, item in
            var config = cell.defaultContentConfiguration()
            config.text = item.name

            if (self.selectedTags.contains(item)) {
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
            cell.contentConfiguration = config
            cell.accessories = [.disclosureIndicator()]
        }

        let datasource = UICollectionViewDiffableDataSource<Int, ListItem>(collectionView: collectionview) { collectionView, indexPath, itemIdentifier in
            switch itemIdentifier {
            case .tag(let tag):
                return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: tag)
            case .button(let title):
                return collectionView.dequeueConfiguredReusableCell(using: buttonCellRegistration, for: indexPath, item: title)
            }
        }

        return datasource
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(setup), name: .UserDidAddTag, object: nil)

        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.title = "Select tags"
        
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
        if let tags = try? account.fetchAllTags() {
            snapshot.appendItems(tags.map { .tag($0) }, toSection: 0)
        }
        snapshot.appendItems([.button("Add new tag")], toSection: 1)

        datasource.apply(snapshot, animatingDifferences: false)
    }

    private func update(at indexPath: IndexPath) {
        guard let item = datasource.itemIdentifier(for: indexPath) else { return }

        var snapshot = datasource.snapshot()
        snapshot.reconfigureItems([item])

        datasource.apply(snapshot, animatingDifferences: false)
    }
}

extension MultipleSelectionList: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = datasource.itemIdentifier(for: indexPath) else { return }

        switch item {
        case .tag(let tag):
            selectedTags.toggle(tag)
            delegate?.multipleselectionlist(self, didUpdateSelectedTags: Array(selectedTags))
            update(at: indexPath)
        case .button:
            let view = AddCategoryView(account: account, configuration: .tag)
            let vc = UIHostingController(rootView: view)
            navigationController?.present(vc, animated: true)
        }

        collectionView.deselectItem(at: indexPath, animated: false)
    }
}
