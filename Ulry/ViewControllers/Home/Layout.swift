//
//  Layout.swift
//  Ulry
//
//  Created by Mattia Righetti on 10/16/22.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import UIKit

extension HomeCollectionView {
    private var mainSection: NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: .init(
                widthDimension: .fractionalWidth(0.5),
                heightDimension: .estimated(200)
            )
        )
        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 6, bottom: 0, trailing: 6)

        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: .init(
                widthDimension: .fractionalWidth(1),
                heightDimension: .estimated(200)
            ),
            subitems: [item]
        )

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 16, bottom: 30, trailing: 16)
        section.interGroupSpacing = 12

        return section
    }

    private var groupSection: NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: .init(
                widthDimension: .fractionalWidth(1),
                heightDimension: .estimated(86)
            )
        )

        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: .init(
                widthDimension: .fractionalWidth(1),
                heightDimension: .estimated(86)
            ),
            subitems: [item]
        )

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 20, trailing: 16)
        section.interGroupSpacing = 12
        section.boundarySupplementaryItems = [
            .init(
                layoutSize: .init(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .absolute(56)
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
            }

            return nil
        }

        return sectionProvider
    }
}
