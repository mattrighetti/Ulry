//
//  BackupCollectionViewController.swift
//  Ulry
//
//  Created by Mattia Righetti on 10/26/22.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import UIKit

private enum Setting: Hashable {
    case icon
    case theme
    case cellAppearance
    
    var icon: String {
        switch self {
            case .icon: return "app"
            case .theme: return "paintpalette.fill"
            case .cellAppearance: return "list.bullet.below.rectangle"
        }
    }
    
    var title: String {
        switch self {
            case .icon: return "App icon"
            case .theme: return "Theme color"
            case .cellAppearance: return "Link appearance"
        }
    }
    
    var hexColor: String {
        switch self {
            case .icon: return "F39C12"
            case .theme: return "E67E22"
            case .cellAppearance: return "2980B9"
        }
    }
}

class AppearanceViewController: UIViewController {
    private lazy var collectionview: UICollectionView = {
        var config = UICollectionLayoutListConfiguration.withCustomBackground(appearance: .insetGrouped)
        let layout = UICollectionViewCompositionalLayout.list(using: config)
        
        let collectionview = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionview.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        collectionview.translatesAutoresizingMaskIntoConstraints = false
        return collectionview
    }()
    
    private lazy var datasource: UICollectionViewDiffableDataSource<Int, Setting> = {
        // MARK: - Cell Configuration
        
        let settingsCellConfiguration = UICollectionView.CellRegistration<UICollectionViewCellCustomBackground, Setting> { cell, indexPath, content in
            var configuration = cell.defaultContentConfiguration()
            
            configuration.text = content.title
            configuration.imageToTextPadding = 10
            configuration.imageProperties.tintColor = .white
            configuration.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 15, leading: 15, bottom: 15, trailing: 0)
            
            cell.contentConfiguration = configuration
            
            let customImage = UICellAccessory.CustomViewConfiguration(
                customView: BackgroundImage.getHostingViewController(icon: content.icon, hex: content.hexColor),
                placement: .leading()
            )
            
            cell.accessories = [.disclosureIndicator(), .customView(configuration: customImage)]
        }
        
        // MARK: - DataSource
        let datasource = UICollectionViewDiffableDataSource<Int, Setting>(collectionView: collectionview) { collectionView, indexPath, s in
            return collectionView.dequeueConfiguredReusableCell(using: settingsCellConfiguration, for: indexPath, item: s)
        }
        
        return datasource
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Appearance"
        
        collectionview.delegate = self
        view.addSubview(collectionview)
        
        setup()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionview.frame = view.bounds
    }
    
    func setup() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, Setting>()
        snapshot.appendSections([0])
        snapshot.appendItems([.icon, .theme, .cellAppearance], toSection: 0)
        datasource.apply(snapshot, animatingDifferences: false)
    }
    
}

extension AppearanceViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let setting = datasource.itemIdentifier(for: indexPath) else { return }
        
        switch setting {
            case .icon:
                navigationController?.pushViewController(AppIconsViewController(), animated: true)
            case .theme:
                let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                alert.addAction(UIAlertAction(title: "Light", style: .default, handler: { _ in
                    UserDefaultsWrapper().set(Theme.light.rawValue, forKey: .theme)
                }))
                
                alert.addAction(UIAlertAction(title: "Dark", style: .default, handler: { _ in
                    UserDefaultsWrapper().set(Theme.dark.rawValue, forKey: .theme)
                }))
                
                alert.addAction(UIAlertAction(title: "System", style: .default, handler: { _ in
                    UserDefaultsWrapper().set(Theme.system.rawValue, forKey: .theme)
                }))
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                present(alert, animated: true)
            case .cellAppearance:
                navigationController?.pushViewController(LinkCellAppearenceViewController(), animated: true)
        }
        
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}
