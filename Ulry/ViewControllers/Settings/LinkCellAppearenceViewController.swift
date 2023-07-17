//
//  LinkCellAppearenceViewController.swift
//  Ulry
//
//  Created by Mattia Righetti on 10/19/22.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import Links
import UIKit

class LinkCellAppearenceViewController: UIViewController {
    
    private enum DataKind: Equatable, Hashable {
        case link(Link)
        case setting(name: String, description: String, appearence: LinkCollectionViewCell.Appearence)
    }
    
    private var selectedSettings: LinkCollectionViewCell.Appearence {
        get {
            LinkCollectionViewCell.Appearence(rawValue: UserDefaultsWrapper().get(key: .linkCellAppearence)!)!
        }
        set {
            UserDefaultsWrapper().set(newValue.rawValue, forKey: .linkCellAppearence)
            refreshSections()
        }
    }
    
    private var sampleLink: Link {
        let link = Link(url: "https://example.com/link")
        link.ogTitle = "Lorem ipsum dolor sit amet"
        link.ogDescription = "consectetur adipiscing elit. In euismod dignissim magna, ac accumsan risus rhoncus sed. Aenean sit amet quam eget dui dignissim ultrices. Donec eget porta justo."
        link.tags = Set([Tag(colorHex: "6f3096", name: "Sample"), Tag(colorHex: "#343434", name: "Tag")])
        return link
    }
    
    private var settings: [DataKind] = [
        .setting(name: "Complete", description: "Show image, title and description", appearence: .complete),
        .setting(name: "Standard", description: "Show title, description and tags", appearence: .standard),
        .setting(name: "Minimal", description: "Only show title", appearence: .minimal)
    ]
    
    private var collectionview: UICollectionView = {
        let sectionProvider = { (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            var configuration: UICollectionLayoutListConfiguration
            if sectionIndex == 0 {
                configuration = UICollectionLayoutListConfiguration.withCustomBackground(appearance: .plain)
                configuration.showsSeparators = false
            } else {
                configuration = UICollectionLayoutListConfiguration.withCustomBackground(appearance: .insetGrouped)
            }
            
            return NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: layoutEnvironment)
        }
        
        let layout = UICollectionViewCompositionalLayout(sectionProvider: sectionProvider)
        
        let collectionview = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionview.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        collectionview.translatesAutoresizingMaskIntoConstraints = false
        return collectionview
    }()
    
    private lazy var datasource: UICollectionViewDiffableDataSource<Int, DataKind> = {
        
        // MARK: - Cell registrations
        
        let linkCellConfiguration = UICollectionView.CellRegistration<LinkCollectionViewCell, Link> { cell, indexPath, link in
            cell.link = link
            cell.backgroundColor = .secondarySystemGroupedBackground
        }
        
        let settingsCellConfiguration = UICollectionView.CellRegistration<UICollectionViewCellCustomBackground, DataKind> { [weak self] cell, indexPath, dataKind in
            var configuration = UIListContentConfiguration.subtitleCell()
            guard case .setting(let name, let description, let appearence) = dataKind else { return }
            configuration.text = name
            configuration.secondaryText = description
            configuration.secondaryTextProperties.color = .secondaryLabel
            configuration.textToSecondaryTextVerticalPadding = 5
            configuration.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0)
            cell.contentConfiguration = configuration
            cell.accessories = self?.selectedSettings == appearence ? [.checkmark()] : []
        }
        
        let datasource = UICollectionViewDiffableDataSource<Int, DataKind>(collectionView: collectionview) { collectionView, indexPath, dataKind in
            switch dataKind {
            case .link(let link):
                return collectionView.dequeueConfiguredReusableCell(using: linkCellConfiguration, for: indexPath, item: link)
            case .setting(_, _, _):
                return collectionView.dequeueConfiguredReusableCell(using: settingsCellConfiguration, for: indexPath, item: dataKind)
            }
        }
        
        return datasource
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Link Appearance"
        
        collectionview.delegate = self
        view.addSubview(collectionview)
        
        setup()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionview.frame = view.bounds
    }
    
    private func setup() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, DataKind>()
        
        snapshot.appendSections([0, 1])
        snapshot.appendItems([.link(sampleLink)], toSection: 0)
        snapshot.appendItems(settings, toSection: 1)
        
        datasource.apply(snapshot)
    }
    
    private func refreshSections() {
        var snapshot = datasource.snapshot()
        snapshot.reloadSections([0, 1])
        datasource.apply(snapshot, animatingDifferences: false)
    }
    
}

extension LinkCellAppearenceViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard
            indexPath.section == 1,
            case .setting(_, _, let appearence) = datasource.itemIdentifier(for: indexPath)
        else { return }
        
        selectedSettings = appearence
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
            collectionView.deselectItem(at: indexPath, animated: true)
        })
    }
}
