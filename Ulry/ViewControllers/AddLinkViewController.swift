//
//  AddLinkViewController.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/17/22.
//

import UIKit
import Combine
import SwiftUI

class AddLinkViewController: UIViewController {
    public enum Configuration: Equatable {
        case edit(Link)
        case new
    }
    
    let database = Database.main
    var isEdit = false
    
    var configuration: Configuration = .new {
        didSet {
            setup(with: configuration)
        }
    }
    
    lazy var urlTextFieldLabel: UILabel = {
        let label = UILabel()
        label.text = "URL"
        label.font = UIFont.rounded(ofSize: 17, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var urlTextField: UITextField = {
        let textField = UITextField()
        let accessoryView = UrlTextFieldAccessoryView(frame: CGRect(x: 0, y: 0, width: UIScreen.screenWidth, height: 50))
        
        accessoryView.doneButton.addAction(UIAction { [unowned self] _ in
            textField.resignFirstResponder()
        }, for: .touchUpInside)
        
        accessoryView.pasteButton.addAction(UIAction { [unowned self] _ in
            if UIPasteboard.general.hasStrings {
                self.urlTextField.text?.append(contentsOf: UIPasteboard.general.string ?? "")
            } else {
                let alert = UIAlertController(title: "Nothing to paste", message: "It seems like you don't have anything in your clipboard", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "Ok", style: .cancel)
                
                alert.addAction(okAction)
                present(alert, animated: true, completion: nil)
            }
        }, for: .touchUpInside)
        
        accessoryView.wwwButton.addAction(UIAction { [unowned self] _ in
            self.urlTextField.text?.append(contentsOf: "www.")
        }, for: .touchUpInside)
        
        accessoryView.httpsButton.addAction(UIAction { [unowned self] _ in
            self.urlTextField.text?.append(contentsOf: "https://")
        }, for: .touchUpInside)
        
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: textField.frame.size.height))
        paddingView.backgroundColor = .black.withAlphaComponent(0.2)
        
        textField.layer.cornerRadius = 10
        textField.layer.borderColor = UIColor.clear.cgColor
        textField.keyboardType = .URL
        textField.clearButtonMode = .whileEditing
        textField.placeholder = "Link"
        textField.backgroundColor = .secondarySystemGroupedBackground
        textField.rightViewMode = .whileEditing
        textField.leftView = paddingView
        textField.leftViewMode = .always
        textField.delegate = self
        textField.inputAccessoryView = accessoryView
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    lazy var ogTitleTextFieldLabel: UILabel = {
        let label = UILabel()
        label.text = "Title"
        label.font = UIFont.rounded(ofSize: 17, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var ogTitleTextField: UITextField = {
        let textField = UITextField()
        let accessoryView = UrlTextFieldAccessoryView(frame: CGRect(x: 0, y: 0, width: UIScreen.screenWidth, height: 50))
        
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: textField.frame.size.height))
        paddingView.backgroundColor = .black.withAlphaComponent(0.2)
        
        textField.layer.cornerRadius = 10
        textField.layer.borderColor = UIColor.clear.cgColor
        textField.keyboardType = .default
        textField.clearButtonMode = .whileEditing
        textField.placeholder = "Title"
        textField.backgroundColor = .secondarySystemGroupedBackground
        textField.rightViewMode = .whileEditing
        textField.leftView = paddingView
        textField.leftViewMode = .always
        textField.delegate = self
        textField.inputAccessoryView = accessoryView
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    lazy var noteTextViewLabel: UILabel = {
        let label = UILabel()
        label.text = "Note"
        label.font = UIFont.rounded(ofSize: 17, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var noteTextView: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.rounded(ofSize: 17, weight: .regular)
        let accessoryView = UrlTextFieldAccessoryView(frame: CGRect(x: 0, y: 0, width: UIScreen.screenWidth, height: 50))
        accessoryView.httpsButton.isHidden = true
        accessoryView.wwwButton.isHidden = true
        accessoryView.pasteButton.isHidden = true
        
        accessoryView.doneButton.addAction(UIAction { [unowned self] _ in
            textView.resignFirstResponder()
        }, for: .touchUpInside)
        
        textView.delegate = self
        textView.backgroundColor = .secondarySystemGroupedBackground
        textView.layer.cornerRadius = 10
        
        textView.inputAccessoryView = accessoryView
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    
    lazy var groupsLabel: UILabel = {
        let label = UILabel()
        label.text = "Group"
        label.font = UIFont.rounded(ofSize: 17, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var tagsLabel: UILabel = {
        let label = UILabel()
        label.text = "Tags"
        label.font = UIFont.rounded(ofSize: 17, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var tagsButton: UIButton = {
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
        
        button.addAction(UIAction { _ in
            self.showTagsMultiselectionList()
        }, for: .touchUpInside)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    lazy var groupsButton: UIButton = {
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
        
        button.addAction(UIAction { _ in
            self.showGroupsSelectionList()
        }, for: .touchUpInside)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    var selectedTagsStringValue: String {
        if selectedTags.isEmpty {
            return "None"
        }
        return selectedTags.map { $0.name }.joined(separator: ", ")
    }
    
    var selectedFolderStringValue: String {
        selectedFolder == nil ? "None" : selectedFolder!.name
    }
    
    private var selectedFolder: Group? = nil {
        didSet {
            groupsButton.setNeedsUpdateConfiguration()
        }
    }
    
    private var selectedTags: [Tag] = [] {
        didSet {
            tagsButton.setNeedsUpdateConfiguration()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.rightBarButtonItem = UIBarButtonItem(systemItem: .save, primaryAction: UIAction { [unowned self] _ in
            guard let url = self.urlTextField.text, !url.isEmpty, let _ = URL(string: url) else {
                let alert = UIAlertController(title: "No URL inserted", message: "Please make sure to insert a valid URL", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                present(alert, animated: true)
                return
            }
            
            switch self.configuration {
            case .edit(let editedLink):
                editedLink.note = self.noteTextView.text
                editedLink.ogTitle = self.ogTitleTextField.text
                editedLink.unread = true
                editedLink.group = self.selectedFolder
                editedLink.tags = Set(self.selectedTags)
                _ = database.update(editedLink)
                
            case .new:
                let link = Link(url: url, note: self.noteTextView.text)
                link.group = self.selectedFolder
                link.tags = Set(self.selectedTags)
                _ = database.insert(link)
                
                MetadataProvider.shared.fetchLinkMetadata(link: link)
            }
            
            self.dismiss(animated: true)
        })
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .close, primaryAction: UIAction { _ in
          self.dismiss(animated: true)
        })
        
        view.backgroundColor = .systemGroupedBackground
        
        setup()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        autoPasteFromClipboard()
    }
    
    private func setup() {
        if isEdit {
            view.addSubview(ogTitleTextFieldLabel)
            view.addSubview(ogTitleTextField)
        } else {
            view.addSubview(urlTextFieldLabel)
            view.addSubview(urlTextField)
        }
        
        view.addSubview(noteTextViewLabel)
        view.addSubview(noteTextView)
        view.addSubview(groupsLabel)
        view.addSubview(groupsButton)
        view.addSubview(tagsLabel)
        view.addSubview(tagsButton)
        
        if isEdit {
            NSLayoutConstraint.activate([
                ogTitleTextFieldLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
                ogTitleTextFieldLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 25),
                ogTitleTextField.topAnchor.constraint(equalTo: ogTitleTextFieldLabel.bottomAnchor, constant: 10),
                ogTitleTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
                ogTitleTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
                ogTitleTextField.heightAnchor.constraint(equalToConstant: 50),
                noteTextViewLabel.topAnchor.constraint(equalTo: ogTitleTextField.bottomAnchor, constant: 20),
            ])
        } else {
            NSLayoutConstraint.activate([
                urlTextFieldLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
                urlTextFieldLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 25),
                urlTextField.topAnchor.constraint(equalTo: urlTextFieldLabel.bottomAnchor, constant: 10),
                urlTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
                urlTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
                urlTextField.heightAnchor.constraint(equalToConstant: 50),
                noteTextViewLabel.topAnchor.constraint(equalTo: urlTextField.bottomAnchor, constant: 20),
            ])
        }
        
        NSLayoutConstraint.activate([
            noteTextViewLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 25),
            noteTextView.topAnchor.constraint(equalTo: noteTextViewLabel.bottomAnchor, constant: 10),
            noteTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            noteTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
            noteTextView.heightAnchor.constraint(equalToConstant: 100),
            groupsLabel.topAnchor.constraint(equalTo: noteTextView.bottomAnchor, constant: 20),
            groupsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 25),
            groupsButton.topAnchor.constraint(equalTo: groupsLabel.bottomAnchor, constant: 10),
            groupsButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            groupsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
            tagsLabel.topAnchor.constraint(equalTo: groupsButton.bottomAnchor, constant: 20),
            tagsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 25),
            tagsButton.topAnchor.constraint(equalTo: tagsLabel.bottomAnchor, constant: 10),
            tagsButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            tagsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15)
        ])
    }
    
    @objc private func showGroupsSelectionList() {
        let view = SelectionList(
            selection: .init(
                get: { self.selectedFolder },
                set: { group in self.selectedFolder = group }
            ), items: database.getAllGroups()
        )
        
        navigationController?.pushViewController(UIHostingController(rootView: view), animated: true)
    }
    
    @objc private func showTagsMultiselectionList() {
        let view = MultipleSelectionList(
            items: database.getAllTags(), selections: selectedTags,
            selectedTags: .init(
                get: { self.selectedTags },
                set: { tags in self.selectedTags = tags }
            )
        )
        
        navigationController?.pushViewController(UIHostingController(rootView: view), animated: true)
    }
    
    private func setup(with configuration: Configuration) {
        switch configuration {
        case .edit(let link):
            self.isEdit = true
            self.urlTextField.text = link.url
            self.noteTextView.text = link.note
            self.ogTitleTextField.text = link.ogTitle
            self.selectedFolder = database.getGroups(of: link).first // TODO not cool looking
            self.selectedTags = database.getTags(of: link)
        case .new: break
        }
    }
    
    private func autoPasteFromClipboard() {
        guard self.configuration == .new else { return }
        if UIPasteboard.general.hasStrings {
            guard let value = UIPasteboard.general.url else { return }
            self.urlTextField.text?.append(contentsOf: value.absoluteString)
        }
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
