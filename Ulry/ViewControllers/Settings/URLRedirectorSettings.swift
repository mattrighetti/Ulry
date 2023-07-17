//
//  URLRedirectorSettings.swift
//  Ulry
//
//  Created by Mattia Righetti on 10/20/22.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import os
import UIKit
import SwiftUI

class URLRedirectorSettings: UIViewController {
    
    private lazy var collectionview: UICollectionView = {
        var config = UICollectionLayoutListConfiguration.withCustomBackground(appearance: .insetGrouped)
        let layout = UICollectionViewCompositionalLayout.list(using: config)
        let collectionview = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionview.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionview.translatesAutoresizingMaskIntoConstraints = false
        return collectionview
    }()
    
    private lazy var datasource: UICollectionViewDiffableDataSource<Int, FOSSRedirection> = {
        // MARK: - Cell Configuration
        
        let settingsCellConfiguration = UICollectionView.CellRegistration<UICollectionViewCellCustomBackground, FOSSRedirection> { cell, indexPath, redirection in
            var configuration = cell.defaultContentConfiguration()
            configuration.text = redirection.title
            configuration.textProperties.font = UIFont.systemFont(ofSize: 17, weight: .regular)
            configuration.textProperties.lineBreakMode = .byClipping
            configuration.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 0)
            cell.contentConfiguration = configuration
        
            var uiswitch: UISwitch {
                let action = UIAction { [weak self] _ in
                    self?.switchPressed(for: indexPath)
                }
                
                let uiswitch = UISwitch()
                uiswitch.isOn = redirection.isActive
                uiswitch.addAction(action, for: .valueChanged)
                return uiswitch
            }
            
            let customViewConfig = UICellAccessory.CustomViewConfiguration(customView: uiswitch, placement: .trailing())
            cell.accessories = [.delete(), .customView(configuration: customViewConfig)]
        }
        
        let buttonCellConfiguration = UICollectionView.CellRegistration<UICollectionViewListCell, String> { cell, indexPath, content in
            var configuration = cell.defaultContentConfiguration()
            configuration.text = content
            cell.contentConfiguration = configuration
            cell.accessories = [.disclosureIndicator()]
        }
        
        // MARK: - DataSource
        let datasource = UICollectionViewDiffableDataSource<Int, FOSSRedirection>(collectionView: collectionview) { collectionView, indexPath, s in
            return collectionView.dequeueConfiguredReusableCell(using: settingsCellConfiguration, for: indexPath, item: s)
        }
        
        return datasource
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Redirector"
        
        collectionview.delegate = self
        view.addSubview(collectionview)

        setup()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionview.frame = view.bounds
    }
    
    private func setup() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, FOSSRedirection>()
        snapshot.appendSections([0])
        snapshot.appendItems([.medium, .reddit, .youtube, .twitter, .reuters], toSection: 0)
        datasource.apply(snapshot, animatingDifferences: false)
    }
    
    func switchPressed(for indexPath: IndexPath) {
        if let redirection = datasource.itemIdentifier(for: indexPath) {
            redirection.toggle()
        } else {
            os_log(.error, "redirection was not found")
        }
    }
}

extension URLRedirectorSettings: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return false
    }
}
