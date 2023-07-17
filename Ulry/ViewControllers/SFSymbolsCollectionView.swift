//
//  SFSymbolsCollectionView.swift
//  Ulry
//
//  Created by Mattia Righetti on 10/18/22.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import UIKit

protocol SFSymbolsCollectionViewDelegate: AnyObject {
    func sfsymbolscollectionview(_ sfsymbolscollectionview: SFSymbolsCollectionView, didSelect icon: String)
}

class SFSymbolsCollectionView: UIViewController {
    
    weak var delegate: SFSymbolsCollectionViewDelegate?
    
    var searchText: String? {
        didSet {
            setupDatasource()
        }
    }
    
    lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewCompositionalLayout(section: section))
        cv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return cv
    }()
    
    // MARK: - Data Source
    
    lazy var datasource: UICollectionViewDiffableDataSource<Int, String> = {
        
        let mainSectionCellRegistration = UICollectionView.CellRegistration<UICollectionViewCell, String> { cell, indexPath, string in
            let configuration = UIImage.SymbolConfiguration(font: UIFont.systemFont(ofSize: 5))
            var imageView = UIImageView(image: UIImage(systemName: string, withConfiguration: configuration)!)
            imageView.tintColor = UIColor.gray.withAlphaComponent(0.5)
            imageView.contentMode = .scaleAspectFit
            cell.backgroundView = imageView
        }
        
        var datasource = UICollectionViewDiffableDataSource<Int, String>(collectionView: collectionView) { collectionView, indexPath, category in
            return collectionView.dequeueConfiguredReusableCell(using: mainSectionCellRegistration, for: indexPath, item: category)
        }
        
        datasource.supplementaryViewProvider = { collectionview, string, indexPath -> UICollectionReusableView? in
            return nil
        }
        
        return datasource
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let searchController = UISearchController()
        
        navigationItem.title = "Select icon"
        navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .close, primaryAction: UIAction { _ in
            self.dismiss(animated: true)
        })
        navigationItem.searchController = searchController
        
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Find icon"
        searchController.searchBar.delegate = self
        
        collectionView.delegate = self
        view.addSubview(collectionView)
        
        setupDatasource()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.frame = view.bounds
    }
    
    private func setupDatasource() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, String>()
        snapshot.appendSections([0])
        snapshot.appendItems(SFSymbols.all.filter {
            if let searchText = searchText, !searchText.isEmpty {
                return $0.lowercased().contains(searchText.lowercased())
            }
            return true
        }, toSection: 0)
        datasource.apply(snapshot, animatingDifferences: false)
    }
    
}

// MARK: - SearchBarDelegate

extension SFSymbolsCollectionView: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.searchText = nil
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText = searchText
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        print("did end editing")
    }
}

// MARK: - Collection View Delegate

extension SFSymbolsCollectionView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let icon = datasource.itemIdentifier(for: indexPath) else { return }
        delegate?.sfsymbolscollectionview(self, didSelect: icon)
        self.dismiss(animated: true)
    }
}

// MARK: - Layout

extension SFSymbolsCollectionView {
    private var width: CGFloat {
        view.frame.size.width
    }
    
    private var primaryItemWidth: CGFloat {
        switch width {
        case 0..<400:
            return 1/8
        default:
            return 1/16
        }
    }
    
    var section: NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: .init(
                widthDimension: .fractionalWidth(primaryItemWidth),
                heightDimension: .fractionalHeight(1)
            )
        )
        item.contentInsets.trailing = 8
        item.contentInsets.bottom = 5
        
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: .init(
                widthDimension: .fractionalWidth(1),
                heightDimension: .fractionalWidth(primaryItemWidth)
            ),
            subitems: [item]
        )
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets.leading = 16
        return section
    }
}
