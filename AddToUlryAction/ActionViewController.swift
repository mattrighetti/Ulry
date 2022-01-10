//
//  ActionViewController.swift
//  AddToUlryAction
//
//  Created by Mattia Righetti on 1/10/22.
//

import UIKit
import SwiftUI
import CoreData
import MobileCoreServices
import UniformTypeIdentifiers

class ActionViewController: UIViewController {
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.rounded(ofSize: 10, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
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
            print("Error")
        }
        
        view.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
    
    private func handleData(dict: NSDictionary) {
        var title: String
        var description: String?
        var imageUrl: String?
        
        let urlString = dict["url"] as! String
        title = dict["title"] as? String ?? ""
        let dictData = dict["dictData"] as? [String:String]
        
        if title.isEmpty {
            if let ogTitle = dictData?["og:title"] {
                title = ogTitle
            } else if let titleNorm = dictData?["title"] {
                title = titleNorm
            } else if let twitterTitle = dictData?["twitter:card:title"] {
                title = twitterTitle
            }
        }
        
        if let ogDescription = dictData?["og:descripition"] {
            description = ogDescription
        } else if let normDescription = dictData?["description"] {
            description = normDescription
        } else if let twitterDescription = dictData?["tiwtter:card:description"] {
            description = twitterDescription
        }
        
        if let ogImgUrl = dictData?["og:image"] {
            imageUrl = ogImgUrl
        } else if let twitterImage = dictData?["twitter:image:src"] {
            imageUrl = twitterImage
        }
        
        if let imageUrl = imageUrl {
            let task = URLSession.shared.dataTask(with: URL(string: imageUrl)!) { data, response, error in
                DispatchQueue.main.async {
                    LinkStorage.shared.add(
                        url: urlString,
                        ogTitle: title,
                        ogDescription: description,
                        ogImageUrl: imageUrl,
                        colorHex: Color.random.toHex ?? "#333333",
                        note: "",
                        starred: false,
                        unread: true,
                        imageData: data,
                        group: nil,
                        tags: nil
                    )
                }
            }
            
            task.resume()
        } else {
            LinkStorage.shared.add(
                url: urlString,
                ogTitle: title,
                ogDescription: description,
                ogImageUrl: imageUrl,
                colorHex: Color.random.toHex ?? "#333333",
                note: "",
                starred: false,
                unread: true,
                imageData: nil,
                group: nil,
                tags: nil
            )
        }
        
        self.titleLabel.text = "Saved correctly"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: {
            self.extensionContext!.completeRequest(returningItems: nil, completionHandler: nil)
        })
    }
}
