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
    let context = CoreDataStack.shared.managedContext
    
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
        imageview.layer.cornerRadius = 15
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
            print("Error")
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
        var title: String
        var description: String?
        var imageUrl: String?
        
        let urlString = dict["url"] as! String
        title = dict["title"] as? String ?? ""
        
        let dictData = dict["dictData"] as? [String:String]
        
        if title.isEmpty {
            title = dictData?.findFirstValue(keys: URL.titleMeta) ?? ""
        }
        description = dictData?.findFirstValue(keys: URL.descriptionMeta)
        imageUrl = dictData?.findFirstValue(keys: URL.imageMeta)
        
        let newLink = Link(context: self.context)
        newLink.url = urlString
        newLink.ogTitle = title
        newLink.ogDescription = description
        newLink.ogImageUrl = imageUrl
        newLink.group = nil
        newLink.tags = nil
        
        CoreDataStack.shared.saveContext()
        
        if imageUrl != nil {
            let task = URLSession.shared.dataTask(with: URL(string: newLink.ogImageUrl!)!) { data, response, error in
                guard let data = data else {
                    return
                }

                newLink.imageData = data
                CoreDataStack.shared.saveContext()
                DispatchQueue.main.async {
                    self.titleLabel.text = "Saved correctly"
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
                        self.extensionContext!.completeRequest(returningItems: nil, completionHandler: nil)
                    })
                }
            }
            task.resume()
        } else {
            self.titleLabel.text = "Saved correctly"
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
                self.extensionContext!.completeRequest(returningItems: nil, completionHandler: nil)
            })
        }
    }
}
