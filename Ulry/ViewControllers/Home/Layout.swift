//
//  Layout.swift
//  Ulry
//
//  Created by Mattia Righetti on 10/16/22.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import UIKit

extension HomeCollectionView {
    private var width: CGFloat {
        view.frame.size.width
    }
    
    private var primaryItemWidth: CGFloat {
        switch width {
        case 0..<500:
            return 1/2
        default:
            return 1/6
        }
    }
    
    private var secondayItemWidth: CGFloat {
        switch width {
        case 0..<500:
            return 1/2
        case 500..<1000:
            return 1/4
        default:
            return 1/6
        }
    }
    
    private var mainSection: NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: .init(
                widthDimension: .fractionalWidth(primaryItemWidth),
                heightDimension: .absolute(80)
            )
        )
        item.contentInsets.trailing = 10
        item.contentInsets.bottom = 10
        
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: .init(
                widthDimension: .fractionalWidth(1),
                heightDimension: .estimated(500)
            ),
            subitems: [item]
        )
        
        let section = NSCollectionLayoutSection(group: group)
        
        section.contentInsets.leading = 11
        section.contentInsets.trailing = 0

        return section
    }
    
    private var groupSection: NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: .init(
                widthDimension: .fractionalWidth(secondayItemWidth),
                heightDimension: .absolute(70)
            )
        )
        item.contentInsets.trailing = 10
        item.contentInsets.bottom = 10
        
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: .init(
                widthDimension: .fractionalWidth(1),
                heightDimension: .estimated(500)
            ),
            subitems: [item]
        )
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets.leading = 11
        section.contentInsets.trailing = 0
        section.boundarySupplementaryItems = [
            .init(
                layoutSize: .init(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .absolute(50)
                ),
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .topLeading
            )
        ]
        
        return section
    }
    
    private var tagSection: NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: .init(
                widthDimension: .fractionalWidth(secondayItemWidth),
                heightDimension: .absolute(60)
            )
        )
        item.contentInsets.trailing = 10
        item.contentInsets.bottom = 10
        
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: .init(
                widthDimension: .fractionalWidth(1),
                heightDimension: .estimated(300)
            ),
            subitems: [item]
        )
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets.leading = 11
        section.contentInsets.trailing = 0
        section.boundarySupplementaryItems = [
            .init(
                layoutSize: .init(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .absolute(50)
                ),
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .topLeading
            )
        ]
        
        return section
    }
    
    var sectionProvider: UICollectionViewCompositionalLayoutSectionProvider {
        let sectionProvider = { (sectionNumber: Int, _: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            if sectionNumber == 0 {
                return self.mainSection
            } else if sectionNumber == 1 {
                return self.groupSection
            } else if sectionNumber == 2 {
                return self.tagSection
            }
            
            return nil
        }
        
        return sectionProvider
    }
}
