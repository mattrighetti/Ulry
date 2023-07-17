//
//  MSList.swift
//  Ulry
//
//  Created by Mattia Righetti on 10/24/22.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import Links
import UIKit
import Account

protocol MultipleSelectionListDelegate: AnyObject {
    func multipleselectionlist(_ multipleselectionlist: MultipleSelectionList, didUpdateSelectedTags tags: [Tag])
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
    
    private lazy var datasource: UICollectionViewDiffableDataSource<Int, AnyHashable> = {
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
        
        let datasource = UICollectionViewDiffableDataSource<Int, AnyHashable>(collectionView: collectionview) { collectionView, indexPath, itemIdentifier in
            if indexPath.section == 0 {
                return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: itemIdentifier as? Tag)
            } else {
                return collectionView.dequeueConfiguredReusableCell(using: buttonCellRegistration, for: indexPath, item: itemIdentifier as? String)
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
        var snapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
        
        snapshot.appendSections([0, 1])
        if let tags = try? account.fetchAllTags() {
            snapshot.appendItems(tags, toSection: 0)
        }
        snapshot.appendItems(["Add new tag"], toSection: 1)
        
        datasource.apply(snapshot, animatingDifferences: false)
    }
    
    private func update(at indexPath: IndexPath) {
        guard let tag = datasource.itemIdentifier(for: indexPath) else { return }
        
        var snapshot = datasource.snapshot()
        snapshot.reconfigureItems([tag])
        
        datasource.apply(snapshot, animatingDifferences: false)
    }
}

extension MultipleSelectionList: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            guard let tag = datasource.itemIdentifier(for: indexPath) as? Tag else { return }
            selectedTags.toggle(tag)
            delegate?.multipleselectionlist(self, didUpdateSelectedTags: Array(selectedTags))
            update(at: indexPath)
        } else {
            let view = AddCategoryViewController()
            view.account = account
            view.configuration = .tag
            navigationController?.present(UINavigationController(rootViewController: view), animated: true)
        }
        
        collectionView.deselectItem(at: indexPath, animated: false)
    }
}
