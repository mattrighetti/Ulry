//
//  SettingsViewController.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/19/22.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import UIKit
import SwiftUI
import Account

private enum Setting: Hashable, Equatable {
    static func == (lhs: Setting, rhs: Setting) -> Bool {
        return lhs.title == rhs.title
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.title)
    }

    case premium
    case general
    case appearance
    case backup(Account)
    case stats(Account)
    case about
    
    var icon: String {
        switch self {
        case .premium: return "sparkles"
        case .general: return "ellipsis"
        case .appearance: return "paintbrush.fill"
        case .backup: return "cylinder.split.1x2.fill"
        case .stats: return "info"
        case .about: return "at"
        }
    }
    
    var title: String {
        switch self {
        case .premium: return "Go premium"
        case .general: return "General"
        case .appearance: return "Appearance"
        case .backup: return "Backup"
        case .stats: return "Ulry info"
        case .about: return "About"
        }
    }
    
    var hexColor: String {
        switch self {
        case .premium: return "F39C12"
        case .general: return "E75926"
        case .appearance: return "2980B9"
        case .backup: return "34495E"
        case .stats: return "331111"
        case .about: return "1CA7EC"
        }
    }

    var viewController: UIViewController {
        switch self {
        case .premium:
            let alert = UIAlertController(title: "Not available", message: "Premium membership will be available in the first production release", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .cancel))
            return alert
        case .general:
            return GeneralSettingsViewController()
        case .appearance:
            return AppearanceViewController()
        case .backup(let account):
            let vc = BackupViewController()
            vc.account = account
            return vc
        case .stats(let account):
            let vc = UlryInfoViewController()
            vc.account = account
            return vc
        case .about:
            return AboutViewController()
        }
    }
}

class SettingsViewController: UIViewController {

    var account: Account!

    private lazy var collectionview: UICollectionViewCustomBackground = {
        let layout = UICollectionViewCompositionalLayout.list(using: UICollectionLayoutListConfiguration.withCustomBackground(appearance: .insetGrouped))
        
        let collectionview = UICollectionViewCustomBackground(frame: .zero, collectionViewLayout: layout)
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
        
        navigationItem.title = "Settings"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .close, primaryAction: UIAction { [weak self] _ in self?.dismiss(animated: true) })
        
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
        snapshot.appendSections([0, 1, 2])
        snapshot.appendItems([.general, .appearance, .backup(account)], toSection: 0)
        snapshot.appendItems([.stats(account)], toSection: 1)
        snapshot.appendItems([.about], toSection: 2)
        datasource.apply(snapshot, animatingDifferences: false)
    }
    
}

extension SettingsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        defer {
            collectionView.deselectItem(at: indexPath, animated: true)
        }
        guard let setting = datasource.itemIdentifier(for: indexPath) else { return }

        if case .premium = setting {
            present(setting.viewController, animated: true)
        }

        let vc = setting.viewController
        navigationController?.pushViewController(vc, animated: true)
    }
}
