//
//  UICollectionLayoutListConfiguration.swift
//  Ulry
//
//  Created by Mattia Righetti on 17/04/23.
//  Copyright © 2023 Mattia Righetti. All rights reserved.
//

import UIKit

extension UICollectionLayoutListConfiguration {
    static func withCustomBackground(appearance: Self.Appearance) -> Self {
        var layout = self.init(appearance: appearance)
        layout.backgroundColor = UIColor(named: "list-bg-color")
        return layout
    }
}
