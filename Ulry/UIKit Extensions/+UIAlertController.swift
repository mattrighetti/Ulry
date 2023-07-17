//
//  +UIAlertController.swift
//  Ulry
//
//  Created by Matt on 14/12/2022.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import UIKit

extension UIAlertController {
    static func okAlert(title: String?, message: String?) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        return alert
    }
}
