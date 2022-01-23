//
//  LinkSharer.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/22/22.
//

import Foundation
import UIKit

struct LinkSharer {
    static func share(link: Link, in viewController: UIViewController) {
        let activityController = UIActivityViewController(activityItems: [link.url], applicationActivities: nil)
        viewController.present(activityController, animated: true, completion: nil)
    }
}
