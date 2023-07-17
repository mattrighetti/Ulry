//
//  +UIActivityViewController.swift
//  Ulry
//
//  Created by Mattia Righetti on 23/02/23.
//  Copyright © 2023 Mattia Righetti. All rights reserved.
//

import UIKit

extension UIActivityViewController {
    public static func share(file: URL, title: String) -> UIActivityViewController {
        let activity = UIActivityViewController(activityItems: [file], applicationActivities: nil)
        activity.title = title
        activity.excludedActivityTypes = [
            .addToReadingList,
            .assignToContact,
            .markupAsPDF,
            .openInIBooks,
            .saveToCameraRoll,
            .postToFacebook,
            .postToVimeo,
            .postToWeibo,
            .postToFlickr,
            .postToTwitter,
            .postToTencentWeibo
        ]

        if #available(iOS 15.4, *) {
            activity.excludedActivityTypes?.append(.sharePlay)
        }

        return activity
    }
}
