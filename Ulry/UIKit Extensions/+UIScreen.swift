//
//  +UIScreen.swift
//  Urly
//
//  Created by Mattia Righetti on 1/3/22.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import UIKit

extension UIScreen {
    @available(iOS, deprecated: 26.0, message: "Use a UIScreen instance found through context instead")
    static let screenWidth = UIScreen.main.bounds.size.width
    @available(iOS, deprecated: 26.0, message: "Use a UIScreen instance found through context instead")
    static let screenHeight = UIScreen.main.bounds.size.height
    @available(iOS, deprecated: 26.0, message: "Use a UIScreen instance found through context instead")
    static let screenSize = UIScreen.main.bounds.size
}
