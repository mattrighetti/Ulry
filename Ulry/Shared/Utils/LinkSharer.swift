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
        let text = "Take a look at \(link.url)!"
        let activityController = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        viewController.present(activityController, animated: true, completion: nil)
    }
}
