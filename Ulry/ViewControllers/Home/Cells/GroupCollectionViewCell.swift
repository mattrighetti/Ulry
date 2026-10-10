//
//  GroupCategoryCollectionViewCell.swift
//  Ulry
//
//  Created by Mattia Righetti on 10/10/22.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import UIKit
import SwiftUI

class GroupCollectionViewCell: BouncyCollectionViewCell {
    var longPressAction: (() -> Void)? = nil

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        let lpr = UILongPressGestureRecognizer(target: self, action: #selector(longPressGesture))
        lpr.minimumPressDuration = 0.5
        addGestureRecognizer(lpr)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(with category: Category) {
        contentConfiguration = UIHostingConfiguration {
            HomeGlassCategoryCard(category: category, style: .row)
        }
        .margins(.all, 0)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        longPressAction = nil
    }

    @objc private func longPressGesture(gesture: UILongPressGestureRecognizer!) {
        guard gesture.state == .began else { return }
        longPressAction?()
    }
}
