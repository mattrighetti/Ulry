//
//  ActionViewController.swift
//  AddToUlryAction
//
//  Created by Mattia Righetti on 1/10/22.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import UIKit
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

    private var loadTask: Task<Void, Never>?

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Save to Ulry"

        let closeButton = UIButton(type: .system)
        closeButton.setTitle("Close", for: .normal)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addAction(UIAction { [weak self] _ in
            self?.loadTask?.cancel()
            self?.extensionContext?.cancelRequest(withError: NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError))
        }, for: .touchUpInside)
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)
        view.addSubview(image)
        view.addSubview(closeButton)
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),
            image.centerXAnchor.constraint(equalTo: titleLabel.centerXAnchor),
            image.bottomAnchor.constraint(equalTo: titleLabel.topAnchor, constant: -20),
            image.widthAnchor.constraint(equalToConstant: 150),
            image.heightAnchor.constraint(equalToConstant: 150),
            closeButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            closeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            closeButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])

        let items = extensionContext?.inputItems.compactMap { $0 as? NSExtensionItem } ?? []
        let providers = items.flatMap { $0.attachments ?? [] }
        loadTask = Task { [weak self] in
            for provider in providers {
                guard !Task.isCancelled else { return }
                guard provider.hasItemConformingToTypeIdentifier(UTType.propertyList.identifier) else { continue }
                do {
                    let item = try await provider.loadItem(forTypeIdentifier: UTType.propertyList.identifier)
                    guard !Task.isCancelled else { return }
                    guard let url = SharedWebURL.fromJavaScriptItem(item) else { continue }
                    self?.save(url)
                    return
                } catch {
                    continue
                }
            }
            self?.showFailure("Couldn't read this link. Try sharing the page again.")
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        loadTask?.cancel()
    }

    private func save(_ url: URL) {
        switch file.save(url.absoluteString, note: nil) {
        case .saved:
            titleLabel.text = "Saved correctly"
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.extensionContext?.completeRequest(returningItems: nil)
            }
        case .full:
            showFailure("Open Ulry to import your saved links, then try again.")
        case .invalidURL:
            showFailure("Please share a valid web link.")
        case .storageFailure:
            showFailure("Couldn't save this link. Open Ulry, then try again.")
        }
    }

    private func showFailure(_ message: String) {
        titleLabel.text = message
        titleLabel.textColor = .systemRed
        image.image = UIImage(systemName: "exclamationmark.triangle")
    }
}
