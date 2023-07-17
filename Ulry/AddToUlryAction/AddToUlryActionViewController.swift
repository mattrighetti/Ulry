//
//  ActionViewController.swift
//  AddToUlryAction
//
//  Created by Mattia Righetti on 1/10/22.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import os
import UIKit
import SwiftUI
import CoreData
import MobileCoreServices
import UniformTypeIdentifiers

class ActionViewController: UIViewController {

    let file = ExtensionsAddLinkRequestsManager()
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Fetching data..."
        label.font = UIFont.rounded(ofSize: 18, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var image: UIImageView = {
        let imageview = UIImageView()
        imageview.image = UIImage(named: "AppIcon")
        imageview.layer.cornerRadius = 35
        imageview.clipsToBounds = true
        imageview.contentMode = .scaleToFill
        imageview.translatesAutoresizingMaskIntoConstraints = false
        return imageview
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Action"
        
        let extensionItem = extensionContext?.inputItems.first as! NSExtensionItem
        let itemProvider = (extensionItem.attachments?.first)! as NSItemProvider
        
        let propertyList = String(describing: UTType.propertyList)
        if itemProvider.hasItemConformingToTypeIdentifier(propertyList) {
            itemProvider.loadItem(forTypeIdentifier: propertyList, options: nil) { item, error in
                let dictionary = item as! NSDictionary
                OperationQueue.main.addOperation { [weak self] in
                    if let results = dictionary[NSExtensionJavaScriptPreprocessingResultsKey] as? NSDictionary {
                        self?.handleData(dict: results)
                    }
                }
            }
        } else {
            os_log(.error, "Encountered error while trying to insert link from action")
        }
        
        view.addSubview(titleLabel)
        view.addSubview(image)
        
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            image.centerXAnchor.constraint(equalTo: titleLabel.centerXAnchor),
            image.bottomAnchor.constraint(equalTo: titleLabel.topAnchor, constant: -20),
            image.widthAnchor.constraint(equalToConstant: 150),
            image.heightAnchor.constraint(equalToConstant: 150)
        ])
    }
    
    private func handleData(dict: NSDictionary) {
        var delay: DispatchTime = .now() + 1.0
        if file.canSaveMoreLinks {
            let urlString = dict["url"] as! String
            guard let _ = URL(string: urlString) else { return }
            file.add(urlString, note: nil)
            titleLabel.text = "Saved correctly"
        } else {
            let conf = UIImage.SymbolConfiguration(paletteColors: [.yellow])
            image.image = UIImage(systemName: "exclamationmark.triangle.fill", withConfiguration: conf)
            titleLabel.text = "Can't save anymore links"
            titleLabel.textColor = .systemRed
            delay = .now() + 3.0
        }

        DispatchQueue.main.asyncAfter(deadline: delay, execute: {
            self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
        })
    }
}
