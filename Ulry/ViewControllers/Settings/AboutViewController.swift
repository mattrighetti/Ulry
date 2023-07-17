//
//  AboutViewController.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/19/22.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import UIKit
import SwiftUI

private enum Setting: Hashable {
    case contact
    case website
    case privacyPolicy
    case changelog
    case reddit
    case github
    case rate
    
    var icon: String {
        switch self {
            case .contact: return "envelope.fill"
            case .website: return "network"
            case .privacyPolicy: return "hand.raised.fill"
            case .changelog: return "sparkles"
            case .rate: return "star.fill"
            case .github: return "asset:github-logo"
            case .reddit: return "tag.fill"
        }
    }
    
    var title: String {
        switch self {
            case .contact: return "Contact"
            case .website: return "Ulry Website"
            case .privacyPolicy: return "Privacy Policy"
            case .changelog: return "What's new"
            case .rate: return "Rate Ulry"
            case .github: return "UlryApp GitHub"
            case .reddit: return "UlryApp Subreddit"
        }
    }
    
    var hexColor: String {
        switch self {
            case .contact: return "615eab"
            case .website: return "43baad"
            case .privacyPolicy: return "1d0a60"
            case .changelog: return "34495E"
            case .rate: return "F1C40F"
            case .github: return "000000"
            case .reddit: return "FC2C07"
        }
    }

    var isLink: Bool {
        switch self {
        case .changelog: return false
        default: return true
        }
    }

    var shouldSelect: Bool {
        return true
    }
}

class AboutViewController: UIViewController {
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

            if !content.shouldSelect {
                configuration.textProperties.color = .systemGray
            }
            
            cell.contentConfiguration = configuration
            
            let customImage = UICellAccessory.CustomViewConfiguration(
                customView: BackgroundImage.getHostingViewController(icon: content.icon, hex: content.hexColor),
                placement: .leading()
            )

            let trailingIcon: UICellAccessory
            if content.isLink {
                let arrowImage = UIImage(systemName: "arrow.up.right")
                let imageView = UIImageView(image: arrowImage)
                imageView.tintColor = UIColor(hex: "C5C5C7")!
                let configuration = UICellAccessory.CustomViewConfiguration(customView: imageView, placement: .trailing())
                trailingIcon = .customView(configuration: configuration)
            } else {
                trailingIcon = .disclosureIndicator()
            }
            
            cell.accessories = [trailingIcon, .customView(configuration: customImage)]
        }
        
        // MARK: - DataSource
        let datasource = UICollectionViewDiffableDataSource<Int, Setting>(collectionView: collectionview) { collectionView, indexPath, s in
            return collectionView.dequeueConfiguredReusableCell(using: settingsCellConfiguration, for: indexPath, item: s)
        }
        
        return datasource
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "About"
        
        collectionview.delegate = self
        view.addSubview(collectionview)
        
        setup()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionview.frame = view.bounds
    }

    private func setup() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, Setting>()
        snapshot.appendSections([0, 1])
        snapshot.appendItems([.changelog, .reddit, .github, .privacyPolicy, .contact, .website], toSection: 0)
        snapshot.appendItems([.rate], toSection: 1)
        datasource.apply(snapshot, animatingDifferences: false)
    }
}

extension AboutViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let setting = datasource.itemIdentifier(for: indexPath) else { return }
        defer {
            collectionView.deselectItem(at: indexPath, animated: true)
        }
        
        switch setting {
        case .contact:
            UIApplication.shared.open(URL(string: "mailto:matt95.righetti+ulry@gmail.com")!)
        case .website:
            UIApplication.shared.open(URL(string: "https://ulry.app")!)
        case .github:
            UIApplication.shared.open(URL(string: "https://github.com/mattrighetti/Ulry")!)
        case .privacyPolicy:
            UIApplication.shared.open(URL(string: "https://ulry.app/privacy-policy")!)
        case .changelog:
            present(ChangelogViewController(), animated: true) {
                if let sheet = $0.sheetPresentationController {
                    sheet.detents = [.large()]
                    sheet.preferredCornerRadius = 25.0
                    sheet.largestUndimmedDetentIdentifier = .medium
                    sheet.prefersScrollingExpandsWhenScrolledToEdge = false
                    sheet.prefersGrabberVisible = false
                }
            }
        case .rate:
            let appReviewManager = AppReviewManager()
            appReviewManager.openAppStoreForReview()
        case .reddit:
            UIApplication.shared.open(URL(string: "https://www.reddit.com/r/UlryApp")!)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return datasource.itemIdentifier(for: indexPath)?.shouldSelect ?? false
    }
}
