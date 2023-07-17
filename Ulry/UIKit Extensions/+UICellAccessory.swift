//
//  +UICellAccessory.swift
//  Ulry
//
//  Created by Mattia Righetti on 24/03/23.
//  Copyright © 2023 Mattia Righetti. All rights reserved.
//

import UIKit

extension UICellAccessory {
    public static func pill(text: String, color: UIColor) -> UICellAccessory.CustomViewConfiguration {
        let pill = UIButton.capsule(text: text, color: color)
        pill.isUserInteractionEnabled = false
        return UICellAccessory.CustomViewConfiguration(customView: pill, placement: .trailing())
    }
}
