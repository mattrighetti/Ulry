//
//  AddLinkViewController.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/17/22.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import os
import UIKit
import Links
import Combine
import Account
import LinksMetadata

class AddLinkViewController: UIViewController {
    public enum Configuration: Equatable {
        case edit(Link)
        case new
    }
    
    var isEdit = false
    var account: Account!
    var configuration: Configuration = .new {
        didSet {
            setup(with: configuration)
        }
    }
    
    private lazy var urlTextField: UITextField = {
        let textField = UITextField()
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: textField.frame.size.height))
        paddingView.backgroundColor = .black.withAlphaComponent(0.2)
        
        textField.layer.cornerRadius = 10
        textField.layer.borderColor = UIColor.clear.cgColor
        textField.keyboardType = .URL
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.clearButtonMode = .whileEditing
        textField.placeholder = "URL"
        textField.backgroundColor = .secondarySystemGroupedBackground
        textField.rightViewMode = .whileEditing
        textField.leftView = paddingView
        textField.leftViewMode = .always
        textField.delegate = self
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private lazy var noteTextViewLabel: UILabel = {
        let label = UILabel()
        label.text = "NOTE"
        label.font = UIFont.preferredFont(for: .callout, weight: .light)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var noteTextView: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.rounded(ofSize: 17, weight: .regular)
        let accessoryView = UrlTextFieldAccessoryView(frame: CGRect(x: 0, y: 0, width: UIScreen.screenWidth, height: 50), withConfiguration: .plain())
        accessoryView.httpsButton.isHidden = true
        accessoryView.wwwButton.isHidden = true
        accessoryView.pasteButton.isHidden = true
        
        accessoryView.doneButton.addAction(UIAction { [unowned self] _ in
            textView.resignFirstResponder()
        }, for: .touchUpInside)
        
        textView.delegate = self
        textView.backgroundColor = .secondarySystemGroupedBackground
        textView.layer.cornerRadius = 10

        let padding = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        textView.textContainerInset = padding
        textView.inputAccessoryView = accessoryView
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    
    private lazy var groupsLabel: UILabel = {
        let label = UILabel()
        label.text = "GROUP"
        label.font = UIFont.preferredFont(for: .callout, weight: .light)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var tagsLabel: UILabel = {
        let label = UILabel()
        label.text = "TAGS"
        label.font = UIFont.preferredFont(for: .callout, weight: .light)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var tagsButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.title = selectedTagsStringValue
        configuration.image = UIImage(systemName: "chevron.right")
        configuration.baseForegroundColor = .systemBlue
        configuration.baseBackgroundColor = .secondarySystemGroupedBackground
        configuration.imagePlacement = .trailing
        configuration.imagePadding = 10.0
        configuration.cornerStyle = .medium
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 15, leading: 0, bottom: 15, trailing: 0)
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(scale: .small)
        
        let button = UIButton()
        button.configuration = configuration
        button.configurationUpdateHandler = { [unowned self] button in
            var config = button.configuration
            
            config?.title = selectedTagsStringValue
            config?.image = selectedTagsStringValue == "None" ? UIImage(systemName: "chevron.right") : nil
            
            button.configuration = config
        }
        
        let showTagsMultiselectionListAction = UIAction { [unowned self] _ in showTagsMultiselectionList() }
        button.addAction(showTagsMultiselectionListAction, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var groupsButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.title = selectedFolderStringValue
        configuration.image = UIImage(systemName: "chevron.right")
        configuration.baseForegroundColor = .systemBlue
        configuration.baseBackgroundColor = .secondarySystemGroupedBackground
        configuration.imagePlacement = .trailing
        configuration.imagePadding = 10.0
        configuration.cornerStyle = .medium
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 15, leading: 0, bottom: 15, trailing: 0)
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(scale: .small)
        
        let button = UIButton()
        button.configuration = configuration
        button.configurationUpdateHandler = { [unowned self] button in
            var config = button.configuration
            
            config?.title = selectedFolderStringValue
            config?.image = selectedFolderStringValue == "None" ? UIImage(systemName: "chevron.right") : nil
            
            button.configuration = config
        }
        
        let showGroupsSelectionListAction = UIAction { [unowned self] _ in showGroupsSelectionList() }
        button.addAction(showGroupsSelectionListAction, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private var selectedTagsStringValue: String {
        if selectedTags.isEmpty {
            return "None"
        }
        return selectedTags.map { $0.name }.joined(separator: ", ")
    }
    
    private var selectedFolderStringValue: String {
        selectedFolder == nil ? "None" : selectedFolder!.name
    }
    
    private var selectedFolder: Links.Group? = nil {
        didSet {
            groupsButton.setTitle(selectedFolderStringValue, for: .normal)
        }
    }
    
    private var selectedTags: [Tag] = [] {
        didSet {
            tagsButton.setTitle(selectedTagsStringValue, for: .normal)
        }
    }

    private lazy var vstack: UIStackView = {
        let vstack = UIStackView()
        vstack.axis = .vertical
        vstack.alignment = .leading
        vstack.distribution = .fillProportionally
        vstack.spacing = 15
        vstack.isLayoutMarginsRelativeArrangement = true
        vstack.layoutMargins = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        vstack.translatesAutoresizingMaskIntoConstraints = false
        return vstack
    }()
    
    private lazy var rightBarButtonItem: UIBarButtonItem = {
        UIBarButtonItem(systemItem: .save, primaryAction: UIAction { [unowned self] _ in
            guard checkTextFieldInputValidity() else { return }
            guard let input = urlTextField.text else { return }
            
            if case .edit(let link) = configuration {
                link.group = selectedFolder
                link.tags = Set(selectedTags)
                link.note = noteTextView.text
                link.ogTitle = urlTextField.text

                Task {
                    await account.update(link: link)
                }
            }
                
            if case .new = configuration {
                let link = Link(url: input)
                link.group = selectedFolder
                link.tags = Set(selectedTags)
                link.note = noteTextView.text

                Task {
                    await account.insert(link: link)
                    await AppReviewManager().registerReviewWorthyAction()
                }
            }
            
            dismiss(animated: true)
        })
    }()
    
    private lazy var leftBarButtonItem: UIBarButtonItem = {
        UIBarButtonItem(systemItem: .close, primaryAction: UIAction { [unowned self] _ in
            dismiss(animated: true)
        })
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.rightBarButtonItem = rightBarButtonItem
        navigationItem.leftBarButtonItem = leftBarButtonItem
        
        view.backgroundColor = .systemGroupedBackground
        
        setup()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    private func setup() {
        vstack.addArrangedSubview(urlTextField)
        vstack.addArrangedSubview(noteTextViewLabel)
        vstack.addArrangedSubview(noteTextView)
        vstack.addArrangedSubview(groupsLabel)
        vstack.addArrangedSubview(groupsButton)
        vstack.addArrangedSubview(tagsLabel)
        vstack.addArrangedSubview(tagsButton)
        
        // Set height and width for each element, otherwise stackview will
        // try to make them fill the space
        for (elem, height) in [
            (urlTextField, 50.0), (noteTextView, 100.0),
            (groupsButton, 50), (tagsButton, 50),
            (noteTextViewLabel, 20), (groupsLabel, 20), (tagsLabel, 20)
        ] {
            let vconstraint = elem.heightAnchor.constraint(equalToConstant: height)
            vconstraint.priority = .init(999)
            vconstraint.isActive = true
            
            let wconstraint = elem.widthAnchor.constraint(equalToConstant: view.frame.width)
            wconstraint.priority = .init(999)
            wconstraint.isActive = true
        }

        view.addSubview(vstack)
        
        NSLayoutConstraint.activate([
            vstack.topAnchor.constraint(equalTo: view.topAnchor, constant: 50),
            vstack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            vstack.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    @objc private func showGroupsSelectionList() {
        let view = SingleSelectionList()
        view.selectedGroup = selectedFolder
        view.account = account
        view.delegate = self
        navigationController?.pushViewController(view, animated: true)
    }
    
    @objc private func showTagsMultiselectionList() {
        let view = MultipleSelectionList()
        view.selectedTags = Set(selectedTags)
        view.account = account
        view.delegate = self
        navigationController?.pushViewController(view, animated: true)
    }

    private func showError(title: String?, message: String) {
        let alert = UIAlertController.okAlert(title: title, message: message)
        present(alert, animated: true)
    }
    
    private func setup(with configuration: Configuration) {
        if case .edit(let link) = configuration {
            isEdit = true
            urlTextField.placeholder = "Title"
            urlTextField.text = link.ogTitle
            urlTextField.keyboardType = .alphabet
            urlTextField.autocorrectionType = .yes
            urlTextField.autocapitalizationType = .none
            noteTextView.text = link.note
            
            selectedFolder = link.group

            if let tags = link.tags {
                selectedTags = Array(tags)
            }
        }
    }
    
    private func autoPasteFromClipboard() {
        guard self.configuration == .new else { return }
        if UIPasteboard.general.hasURLs {
            guard let text = UIPasteboard.general.url else { return }
            self.urlTextField.text = text.absoluteString
        } else if UIPasteboard.general.hasStrings {
            guard let text = UIPasteboard.general.string else { return }
            self.urlTextField.text = text
        }
    }

    private func checkTextFieldInputValidity() -> Bool {
        urlTextField.text = urlTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        // Both edit and new must have valid input
        guard let input = urlTextField.text, !input.isEmpty else {
            showError(title: "Invalid input", message: "Please enter valid text to continue")
            return false
        }

        // This is a new url
        // 1. URL must be valid
        // 2. URL must not be in database (UNIQUE)
        if case .new = configuration {
            guard (input.hasPrefix("https://") || input.hasPrefix("http://")) else {
                showError(title: "Invalid URL", message: "Links must either start with http or https")
                return false
            }

            guard let _ = URL(string: input) else {
                showError(title: "Invalid URL", message: "Please enter a valid URL to continue")
                return false
            }

            // TODO: maybe remove this since database now accepts duplicate links?
            guard try! !account.existsLink(with: input) else {
                // TODO fix error message
                showError(title: "Duplicate link", message: "A link '\(input)' has already been saved previously")
                return false
            }
        }

        return true
    }
}

extension AddLinkViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension AddLinkViewController: UITextViewDelegate {}

extension AddLinkViewController: MultipleSelectionListDelegate {
    func multipleselectionlist(_ multipleselectionlist: MultipleSelectionList, didUpdateSelectedTags tags: [Tag]) {
        selectedTags = tags
    }
}

extension AddLinkViewController: SingleSelectionListDelegate {
    func singleselectionlist(_ singleselectionlist: SingleSelectionList, didSelect group: Links.Group?) {
        selectedFolder = group
    }
}
