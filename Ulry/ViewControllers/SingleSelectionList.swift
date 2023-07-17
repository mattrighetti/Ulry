//
//  SingleSelectionlist.swift
//  Ulry
//
//  Created by Mattia Righetti on 10/25/22.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import Links
import UIKit
import Account

protocol SingleSelectionListDelegate: AnyObject {
    func singleselectionlist(_ singleselectionlist: SingleSelectionList, didSelect group: Group?)
}

class SingleSelectionList: UIViewController {
    
    var selectedGroup: Group? = nil
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
    
    private lazy var datasource: UICollectionViewDiffableDataSource<Int, AnyHashable> = {
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Group> { cell, indexPath, item in
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
        
        let datasource = UICollectionViewDiffableDataSource<Int, AnyHashable>(collectionView: collectionview) { collectionView, indexPath, itemIdentifier in
            if indexPath.section == 0 {
                return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: itemIdentifier as? Group)
            } else {
                return collectionView.dequeueConfiguredReusableCell(using: buttonCellRegistration, for: indexPath, item: itemIdentifier as? String)
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
        var snapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
        
        snapshot.appendSections([0, 1])
        
        if let groups = try? account.fetchAllGroups() {
            snapshot.appendItems(groups, toSection: 0)
        }
        
        snapshot.appendItems(["Add new group"], toSection: 1)
        
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
        if indexPath.section == 0 {
            guard let group = datasource.itemIdentifier(for: indexPath) as? Group else { return }
            
            if (selectedGroup?.id == group.id) {
                selectedGroup = nil
            } else {
                selectedGroup = group
            }
            
            delegate?.singleselectionlist(self, didSelect: selectedGroup)
            reloadItems()
        } else {
            let view = AddCategoryViewController()
            view.account = account
            view.configuration = .group
            navigationController?.present(UINavigationController(rootViewController: view), animated: true)
        }
        
        collectionView.deselectItem(at: indexPath, animated: false)
    }
}
