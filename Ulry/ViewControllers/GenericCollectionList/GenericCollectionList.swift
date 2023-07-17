//
//  GenericCollectionList.swift
//  Ulry
//
//  Created by Mattia Righetti on 10/25/22.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import UIKit

struct CVSetting: Hashable, Equatable {
    let image: String
    let text: String
    let secondaryText: String?
    let accessories: [UICellAccessory]
    let hexColor: String
    var isSelectable: Bool = false
    
    static func == (lhs: CVSetting, rhs: CVSetting) -> Bool {
        return (lhs.image == rhs.image) && (lhs.text == rhs.text)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(image)
        hasher.combine(text)
    }
}

enum CollectionViewCellContent: Hashable, Equatable {
    case navigate(CVSetting, UIViewController)
    case setting(CVSetting)
    
    func getSetting() -> CVSetting {
        switch self {
        case .navigate(let cVSetting, _):
            return cVSetting
        case .setting(let cVSetting):
            return cVSetting
        }
    }
}

class GenericCollectionList: UIViewController {
    
    var content: [[CollectionViewCellContent]]?
    
    private lazy var collectionview: UICollectionViewCustomBackground = {
        var config = UICollectionLayoutListConfiguration.withCustomBackground(appearance: .insetGrouped)
        
        let layout = UICollectionViewCompositionalLayout.list(using: config)
        
        let collectionview = UICollectionViewCustomBackground(frame: .zero, collectionViewLayout: layout)
        collectionview.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        collectionview.translatesAutoresizingMaskIntoConstraints = false
        return collectionview
    }()
    
    private lazy var datasource: UICollectionViewDiffableDataSource<Int, CollectionViewCellContent> = {
        // MARK: - Cell Configuration
        
        let settingsCellConfiguration = UICollectionView.CellRegistration<UICollectionViewCellCustomBackground, CollectionViewCellContent> { cell, indexPath, content in
            var configuration = cell.defaultContentConfiguration()
            
            let setting = content.getSetting()
            configuration.text = setting.text
            configuration.secondaryText = setting.secondaryText
            configuration.secondaryTextProperties.color = .secondaryLabel
            configuration.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 15, leading: 15, bottom: 15, trailing: 0)
            
            cell.contentConfiguration = configuration
            let customImage = UICellAccessory.CustomViewConfiguration(
                customView: BackgroundImage.getHostingViewController(icon: content.getSetting().image, hex: content.getSetting().hexColor),
                placement: .leading()
            )
            
            var v: [UICellAccessory] = [.customView(configuration: customImage)]
            v.append(contentsOf: content.getSetting().accessories)
            
            cell.accessories = v
        }
        
        // MARK: - DataSource
        let datasource = UICollectionViewDiffableDataSource<Int, CollectionViewCellContent>(collectionView: collectionview) { collectionView, indexPath, s in
            return collectionView.dequeueConfiguredReusableCell(using: settingsCellConfiguration, for: indexPath, item: s)
        }
        
        return datasource
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionview.delegate = self
        view.addSubview(collectionview)
        
        NSLayoutConstraint.activate([
            collectionview.topAnchor.constraint(equalTo: view.topAnchor),
            collectionview.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionview.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionview.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    func setup() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, CollectionViewCellContent>()
        
        guard let content = content else { return }
        
        let data = content
        snapshot.appendSections(Array(0..<data.count))
        
        for i in 0..<data.count {
            snapshot.appendItems(data[i], toSection: i)
        }
        
        datasource.apply(snapshot, animatingDifferences: false)
    }
}

extension GenericCollectionList: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        guard let content = datasource.itemIdentifier(for: indexPath) else { return false }
        return content.getSetting().isSelectable
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let content = datasource.itemIdentifier(for: indexPath) else { return }
        guard case .navigate(_, let uIViewController) = content else { return }
        
        self.navigationController?.pushViewController(uIViewController, animated: true)
        
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}
