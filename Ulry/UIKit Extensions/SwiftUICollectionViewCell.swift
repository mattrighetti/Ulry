//
//  SwiftUICollectionViewCell.swift
//  Ulry
//
//  Created by Mattia Righetti on 17/04/23.
//  Copyright © 2023 Mattia Righetti. All rights reserved.
//

import UIKit
import SwiftUI

final class SwiftUICollectionViewCell: UICollectionViewListCell {
    func host<Content: View>(_ hostingController: UIHostingController<Content>) {
        backgroundColor = UIColor(named: "list-bg-color")
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.backgroundColor = UIColor(named: "list-cell-bg-color")
        addSubview(hostingController.view)

        let constraints = [
            hostingController.view.topAnchor.constraint(equalTo: self.topAnchor),
            hostingController.view.leftAnchor.constraint(equalTo: self.leftAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            hostingController.view.rightAnchor.constraint(equalTo: self.rightAnchor),
        ]
        NSLayoutConstraint.activate(constraints)
    }
}
