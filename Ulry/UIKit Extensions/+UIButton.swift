//
//  +UIButton.swift
//  Ulry
//
//  Created by Mattia Righetti on 24/03/23.
//  Copyright © 2023 Mattia Righetti. All rights reserved.
//

import UIKit

extension UIButton {
    public static func capsule(text: String, color: UIColor) -> UIButton {
        var configuration = UIButton.Configuration.filled()
        configuration.cornerStyle = .capsule
        configuration.baseBackgroundColor = color
        configuration.buttonSize = .mini
        configuration.title = text
        return UIButton(configuration: configuration)
    }
}
