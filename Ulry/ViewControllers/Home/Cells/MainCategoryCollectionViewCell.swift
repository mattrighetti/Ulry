//
//  MainCategoryCollectionViewCell.swift
//  Ulry
//
//  Created by Mattia Righetti on 10/10/22.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import UIKit
import SwiftUI

class MainCategoryCollectionViewCell: BouncyCollectionViewCell {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(with category: Category) {
        contentConfiguration = UIHostingConfiguration {
            HomeGlassCategoryCard(category: category, style: .hero)
        }
        .margins(.all, 0)
    }
}
