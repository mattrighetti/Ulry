//
//  ShareViewController.swift
//  UlryShareExtension
//
//  Created by Mattia Righetti on 29/03/2026.
//  Copyright © 2026 Mattia Righetti. All rights reserved.
//

import UIKit
import SwiftUI

final class ShareViewController: UIHostingController<ShareCardView> {

    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: ShareCardView(extensionContext: nil))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        rootView = ShareCardView(extensionContext: extensionContext)
    }
}
