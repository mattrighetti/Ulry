//
//  +UICollectionView.swift
//  Ulry
//
//  Created by Mattia Righetti on 17/04/23.
//  Copyright © 2023 Mattia Righetti. All rights reserved.
//

import UIKit

final class UICollectionViewCustomBackground: UICollectionView {
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        backgroundColor = UIColor(named: "bg-color")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
