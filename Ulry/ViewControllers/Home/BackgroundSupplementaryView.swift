//
//  BackgroundSupplementaryView.swift
//  Ulry
//
//  Created by Mattia Righetti on 17/04/23.
//  Copyright © 2023 Mattia Righetti. All rights reserved.
//

import UIKit

/// A basic supplementary view used for section backgrounds.
final class BackgroundSupplementaryView: UICollectionReusableView {
    override init(frame: CGRect) {
        super.init(frame: frame)

        layer.cornerRadius = 15
        backgroundColor = UIColor(hex: "111111")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
