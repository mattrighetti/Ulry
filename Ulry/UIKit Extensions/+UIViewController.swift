//
//  +UIViewController.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/10/22.
//

import UIKit

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
