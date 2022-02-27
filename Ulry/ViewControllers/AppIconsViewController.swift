//
//  AppIconsViewController.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/27/22.
//

import UIKit

struct AppIconStatus: Hashable {
    let appIcon: AppIcon
    let isCurrentAppIcon: Bool
}

extension UIImage {
    func imageWith(newSize: CGSize) -> UIImage {
        let image = UIGraphicsImageRenderer(size: newSize).image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
            
        return image.withRenderingMode(renderingMode)
    }
}

class AppIconsViewController: UIViewController {
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "AppIconCell")
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    // We can't use the AppIcon enum directly, as enums are static and computed properties on them won't be factored into the diffable data source calculations, so have a pseudo wrapper
    lazy var appIconStatuses: [AppIconStatus] = createAppIconStatuses()
    
    lazy var datasource: UITableViewDiffableDataSource<Int, AppIconStatus> = {
        let datasource = UITableViewDiffableDataSource<Int, AppIconStatus>(tableView: tableView) { tableView, indexPath, appIconStatus in
            let cell = tableView.dequeueReusableCell(withIdentifier: "AppIconCell", for: indexPath)
            
            var contentConfig = UIListContentConfiguration.subtitleCell()
                        
            contentConfig.text = appIconStatus.appIcon.title
            contentConfig.textProperties.font = UIFont.rounded(ofSize: 14, weight: .semibold)
            contentConfig.textToSecondaryTextVerticalPadding = 3.0
            
            contentConfig.image = appIconStatus.appIcon.thumbnail.imageWith(newSize: CGSize(width: 68.0, height: 68.0))
            
            // Add a bit of extra vertical height
            contentConfig.imageProperties.reservedLayoutSize = CGSize(width: 68.0, height: 96.0)
            
            contentConfig.secondaryText = appIconStatus.appIcon.subtitle
            contentConfig.secondaryTextProperties.color = .secondaryLabel
            
            cell.contentConfiguration = contentConfig
            
            cell.accessoryType = appIconStatus.isCurrentAppIcon ? .checkmark : .none
            
            return cell
        }
        return datasource
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "App Icon"
        
        tableView.delegate = self
        view.addSubview(tableView)
        
        refreshAppIcons()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
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

extension AppIconsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let appIconStatus = datasource.itemIdentifier(for: indexPath) else { return }
        
        let alternateIconName: String? = appIconStatus.appIcon == .default ? nil : appIconStatus.appIcon.rawValue
        
        if !UIApplication.shared.supportsAlternateIcons {
            let alert = UIAlertController(title: "Not supported", message: "Sorry, this device does not support changing icon", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            present(alert, animated: false, completion: nil)
            return
        }
        
        UIApplication.shared.setAlternateIconName(alternateIconName) { [weak self] error in
            guard let strongSelf = self else { return }
            
            if let error = error {
                let alertController = UIAlertController(title: "Error Setting Icon :(", message: error.localizedDescription, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Ok", style: .cancel))
                strongSelf.present(alertController, animated: true, completion: nil)
            } else {
                strongSelf.appIconStatuses = strongSelf.createAppIconStatuses()
                strongSelf.refreshAppIcons()
            }
        }
    }
}
