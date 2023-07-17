//
//  ShareViewController.swift
//  UlryShareExtension
//
//  Created by Matt on 10/12/2022.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import UIKit
import SwiftUI
import LinksMetadata
import UniformTypeIdentifiers

enum ShareExtensionError: Error {
    case cannotExtractFromAttachments
    case noAttachmentFound
}

@objc(ShareExtensionViewController)
class ShareViewController: UIViewController {

    var url: URL?

    private let file = ExtensionsAddLinkRequestsManager()

    private lazy var monospaceFont: UIFont = {
        let font = UIFont.monospacedSystemFont(ofSize: 17, weight: .regular)
        return font
    }()

    private lazy var regularFont: UIFont = {
        let font = UIFont.systemFont(ofSize: 20, weight: .bold)
        return font
    }()

    private lazy var bottomLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = monospaceFont
        label.numberOfLines = 3
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var topLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textColor = .secondaryLabel
        label.font = UIFont.systemFont(ofSize: 15,  weight: .regular)
        label.translatesAutoresizingMaskIntoConstraints = false

        return label
    }()

    private lazy var noteTextField: UITextField = {
        let textField = UITextField()

        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: textField.frame.size.height))
        paddingView.backgroundColor = .black.withAlphaComponent(0.2)

        textField.layer.cornerRadius = 10
        textField.layer.borderColor = UIColor.clear.cgColor
        textField.keyboardType = .default
        textField.autocorrectionType = .default
        textField.autocapitalizationType = .sentences
        textField.clearButtonMode = .whileEditing
        textField.placeholder = "Note"
        textField.backgroundColor = .tertiarySystemGroupedBackground
        textField.rightViewMode = .whileEditing
        textField.leftViewMode = .always
        textField.leftView = paddingView
        textField.delegate = self
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()

    private lazy var button: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.title = "Save"
        configuration.baseForegroundColor = .white
        configuration.baseBackgroundColor = .systemBlue
        configuration.imagePlacement = .trailing
        configuration.imagePadding = 10.0
        configuration.cornerStyle = .large
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 15, leading: 0, bottom: 15, trailing: 0)
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(scale: .small)

        let button = UIButton()
        button.configuration = configuration

        let showGroupsSelectionListAction = UIAction { [unowned self] _ in
            self.onSavePressed()
            extensionContext!.completeRequest(returningItems: nil)
        }
        button.addAction(showGroupsSelectionListAction, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var okButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.title = "Ok"
        configuration.baseForegroundColor = .white
        configuration.baseBackgroundColor = .systemBlue
        configuration.imagePlacement = .trailing
        configuration.imagePadding = 10.0
        configuration.cornerStyle = .large
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 15, leading: 0, bottom: 15, trailing: 0)
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(scale: .small)

        let button = UIButton()
        button.configuration = configuration

        let showGroupsSelectionListAction = UIAction { [unowned self] _ in
            extensionContext!.completeRequest(returningItems: nil)
        }
        button.addAction(showGroupsSelectionListAction, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var image: UIImageView = {
        let view = UIImageView()
        let conf = UIImage.SymbolConfiguration(paletteColors: [.yellow])
        view.image = UIImage(systemName: "exclamationmark.triangle.fill", withConfiguration: conf)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 50
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    private func setup() {
        let canSave = file.canSaveMoreLinks

        view.addSubview(backgroundView)
        view.addSubview(topLabel)
        view.addSubview(bottomLabel)
        view.addSubview(button)

        if canSave {
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
            view.addSubview(noteTextField)
        } else {
            view.addSubview(image)
        }


        NSLayoutConstraint.activate([
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            button.heightAnchor.constraint(equalToConstant: 60)
        ])

        if canSave {
            NSLayoutConstraint.activate([
                noteTextField.bottomAnchor.constraint(equalTo: button.topAnchor, constant: -50),
                noteTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                noteTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                noteTextField.heightAnchor.constraint(equalToConstant: 50),
                bottomLabel.bottomAnchor.constraint(equalTo: noteTextField.topAnchor, constant: -30),
            ])
        } else {
            NSLayoutConstraint.activate([
                bottomLabel.bottomAnchor.constraint(equalTo: button.topAnchor, constant: -30),
            ])
        }

        NSLayoutConstraint.activate([
            bottomLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            bottomLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            topLabel.bottomAnchor.constraint(equalTo: bottomLabel.topAnchor, constant: -7),
            topLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            topLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15)
        ])

        if canSave {
            NSLayoutConstraint.activate([
                backgroundView.topAnchor.constraint(equalTo: topLabel.topAnchor, constant: -35),
            ])
        } else {
            NSLayoutConstraint.activate([
                image.bottomAnchor.constraint(equalTo: topLabel.topAnchor, constant: -35),
                image.heightAnchor.constraint(equalToConstant: 70),
                image.widthAnchor.constraint(equalToConstant: 70),
                image.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                backgroundView.topAnchor.constraint(equalTo: image.topAnchor, constant: -35)
            ])
        }

        if canSave {
            Task {
                await handle()
            }
        } else {
            handleWarning()
        }
    }

    private func handleWarning() {
        topLabel.text = "Cannot save any more links"
        topLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        topLabel.textColor = .label

        bottomLabel.text = "You have to open the app and load previously saved links before you can add more externally"
        bottomLabel.textColor = .secondaryLabel
        bottomLabel.font = UIFont.preferredFont(forTextStyle: .body)

        var buttonConf = button.configuration
        buttonConf?.title = "Ok"
        button.configuration = buttonConf
    }

    private func extractUrlFromAttachments() async throws -> String? {
        guard let attachments = (self.extensionContext?.inputItems.first as? NSExtensionItem)?.attachments, attachments.count > 0 else {
            return nil
        }

        for provider in attachments {
            if provider.hasItemConformingToTypeIdentifier(UTType.url.description) {
                let data = try await provider.loadItem(forTypeIdentifier: UTType.url.description, options: nil)
                return (data as? URL)?.absoluteString
            }
        }

        return nil
    }

    private func handle() async {
        guard
            let urlString = try? await extractUrlFromAttachments(),
            let url = URL(string: urlString)
        else {
            extensionContext!.cancelRequest(withError: ShareExtensionError.cannotExtractFromAttachments)
            return
        }

        self.url = url
        bottomLabel.text = urlString
        bottomLabel.textColor = .secondaryLabel
        topLabel.text = url.host

        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let html = String(data: data, encoding: .utf8),
              let og = DefaultOpenGraphData(html: html)
        else { return }

        if let title = og.ogTitle {
            bottomLabel.text = title
            bottomLabel.font = regularFont
        }

        UIView.transition(with: bottomLabel, duration: 0.5, options: .transitionCrossDissolve) {
            self.bottomLabel.textColor = .label
        }
    }

    private func onSavePressed() {
        if let url = self.url {
            file.add(url.absoluteString, note: noteTextField.text)
        }
    }

    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 {
                self.view.frame.origin.y -= keyboardSize.height + 10
            }
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
}

extension ShareViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
}
