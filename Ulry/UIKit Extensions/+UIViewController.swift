//
//  +UIViewController.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/10/22.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import UIKit
import SwiftUI

extension UIViewController {
    func add(_ parent: UIViewController, frame: CGRect?) {
        parent.addChild(self)
        parent.view.addSubview(view)
        if let frame =  frame {
            view.frame = frame
        }
        didMove(toParent: parent)
    }

    func remove() {
        guard parent != nil else { return }

        willMove(toParent: nil)
        removeFromParent()
        view.removeFromSuperview()
    }
}

extension UIViewController {
    func present<Content: View>(_ swiftuiView: Content,  animated: Bool, config: ((UIHostingController<Content>) -> Void)? = nil) {
        let hostingController = UIHostingController(rootView: swiftuiView)
        config?(hostingController)
        present(hostingController, animated: animated)
    }
}
