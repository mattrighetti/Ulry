//
//  UICollectionViewCellCustomBackground.swift
//  Ulry
//
//  Created by Mattia Righetti on 17/04/23.
//  Copyright © 2023 Mattia Righetti. All rights reserved.
//

import UIKit

class UICollectionViewCellCustomBackground: UICollectionViewListCell {
    override func updateConfiguration(using state: UICellConfigurationState) {
        var back = UIBackgroundConfiguration.listCell().updated(for: state)
        if state.isSelected || state.isHighlighted {
            back.backgroundColor = UIColor(named: "list-cell-selected-bg-color")
        } else {
            back.backgroundColor = UIColor(named: "list-cell-bg-color")
        }
        backgroundConfiguration = back
    }
}
