//
//  AppIconsViewController.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/27/22.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import UIKit

struct AppIconStatus: Hashable {
    let appIcon: AppIcon
    let isCurrentAppIcon: Bool
}

class AppIconsViewController: UIViewController {
    private lazy var collectionview: UICollectionView = {
        var config = UICollectionLayoutListConfiguration.withCustomBackground(appearance: .insetGrouped)

        let layout = UICollectionViewCompositionalLayout.list(using: config)

        let collectionview = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionview.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        collectionview.translatesAutoresizingMaskIntoConstraints = false
        return collectionview
    }()
    
    // We can't use the AppIcon enum directly, as enums are static and computed properties on them won't be factored into the diffable data source calculations, so have a pseudo wrapper
    lazy var appIconStatuses: [AppIconStatus] = createAppIconStatuses()

    private lazy var datasource: UICollectionViewDiffableDataSource<Int, AppIconStatus> = {
        // MARK: - Cell Configuration

        let settingsCellConfiguration = UICollectionView.CellRegistration<UICollectionViewCellCustomBackground, AppIconStatus> { cell, indexPath, appIconStatus in
            var contentConfig = cell.defaultContentConfiguration()

            contentConfig.text = appIconStatus.appIcon.title
            contentConfig.textToSecondaryTextVerticalPadding = 3.0

            contentConfig.image = appIconStatus.appIcon.thumbnail.imageWith(newSize: CGSize(width: 68.0, height: 68.0))
            contentConfig.imageProperties.cornerRadius = 15

            // Add a bit of extra vertical height
            contentConfig.imageProperties.reservedLayoutSize = CGSize(width: 68.0, height: 96.0)

            contentConfig.secondaryText = appIconStatus.appIcon.subtitle
            contentConfig.secondaryTextProperties.color = .secondaryLabel

            cell.contentConfiguration = contentConfig

            if appIconStatus.isCurrentAppIcon {
                cell.accessories = [.checkmark()]
            } else {
                cell.accessories = []
            }
        }

        // MARK: - DataSource
        let datasource = UICollectionViewDiffableDataSource<Int, AppIconStatus>(collectionView: collectionview) { collectionView, indexPath, s in
            return collectionView.dequeueConfiguredReusableCell(using: settingsCellConfiguration, for: indexPath, item: s)
        }

        return datasource
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "App Icon"
        
        collectionview.delegate = self
        view.addSubview(collectionview)
        
        refreshAppIcons()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionview.frame = view.bounds
    }
    
    private func createAppIconStatuses() -> [AppIconStatus] {
        var appIconStatuses: [AppIconStatus] = []
        
        for icon in AppIcon.allCases {
            let status = AppIconStatus(appIcon: icon, isCurrentAppIcon: AppIcon.currentAppIcon == icon)
            appIconStatuses.append(status)
        }

        return appIconStatuses
    }
   
    private func refreshAppIcons() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, AppIconStatus>()

        snapshot.appendSections([0])
        snapshot.appendItems(appIconStatuses, toSection: 0)

        datasource.apply(snapshot, animatingDifferences: false)
    }
}

extension AppIconsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)

        guard let appIconStatus = datasource.itemIdentifier(for: indexPath) else { return }

        let alternateIconName: String? = appIconStatus.appIcon == .default ? nil : appIconStatus.appIcon.rawValue

        if !UIApplication.shared.supportsAlternateIcons {
            let alert = UIAlertController(title: "Not supported", message: "Sorry, this device does not support changing icon", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            present(alert, animated: false, completion: nil)
            return
        }

        UIApplication.shared.setAlternateIconName(alternateIconName) { error in
            if let error = error {
                let alertController = UIAlertController(title: "Error Setting Icon :(", message: error.localizedDescription, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Ok", style: .cancel))
                self.present(alertController, animated: true, completion: nil)
            } else {
                self.appIconStatuses = self.createAppIconStatuses()
                self.refreshAppIcons()
            }
        }

    }
}
