//
//  AddLinkViewController.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/17/22.
//

import UIKit
import Combine
import SwiftUI

class UrlTextFieldAccessoryView: UIScrollView {
    lazy var doneButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        configuration.baseForegroundColor = .white
        configuration.attributedTitle = AttributedString("Done", attributes: AttributeContainer([
            NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 15)
        ]))
        
        let button = UIButton(configuration: configuration, primaryAction: nil)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    lazy var wwwButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        configuration.baseForegroundColor = .white
        configuration.attributedTitle = AttributedString("www", attributes: AttributeContainer([
            NSAttributedString.Key.font: UIFont.monospacedSystemFont(ofSize: 13, weight: .bold)
        ]))
        
        let button = UIButton(configuration: configuration, primaryAction: nil)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    lazy var httpsButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        configuration.baseForegroundColor = .white
        configuration.attributedTitle = AttributedString("https", attributes: AttributeContainer([
            NSAttributedString.Key.font: UIFont.monospacedSystemFont(ofSize: 13, weight: .bold)
        ]))
        
        let button = UIButton(configuration: configuration, primaryAction: nil)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    lazy var pasteButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        configuration.baseForegroundColor = .white
        configuration.image = UIImage(systemName: "doc.on.clipboard")
        configuration.imagePlacement = .leading
        configuration.buttonSize = .small
        
        let button = UIButton(configuration: configuration, primaryAction: nil)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    lazy var horizontalStackView: UIStackView = {
        let view = UIStackView()
        view.backgroundColor = .clear
        view.axis = .horizontal
        view.contentMode = .center
        view.distribution = .fillProportionally
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .clear
        contentMode = .center
        isScrollEnabled = true
        contentInset = UIEdgeInsets(top: 8, left: 5, bottom: 0, right: 5)
        alwaysBounceHorizontal = true
        translatesAutoresizingMaskIntoConstraints = false
        
        backgroundColor = UIColor(hex: "#111111")
        addSubview(horizontalStackView)
        horizontalStackView.addArrangedSubview(doneButton)
        horizontalStackView.addArrangedSubview(pasteButton)
        horizontalStackView.addArrangedSubview(httpsButton)
        horizontalStackView.addArrangedSubview(wwwButton)
        
        NSLayoutConstraint.activate([
            horizontalStackView.topAnchor.constraint(equalTo: topAnchor),
            horizontalStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            horizontalStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            horizontalStackView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class AddLinkViewController: UIViewController {
    public enum Configuration {
        case edit(Link)
        case new
    }
    
    let context = CoreDataStack.shared.managedContext
    var configuration: Configuration = .new {
        didSet {
            switch configuration {
            case .edit(let link):
                self.urlTextField.text = link.url
                self.selectedFolder = link.group
                self.selectedTags = Array(link.tags!)
            case .new:
                break
            }
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
    
    lazy var noteTextViewLabel: UILabel = {
        let label = UILabel()
        label.text = "Note"
        label.font = UIFont.rounded(ofSize: 17, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var noteTextView: UITextView = {
        let textView = UITextView()
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
        guard !selectedTags.isEmpty else { return "None" }
        return selectedTags.map { $0.name }.joined(separator: ", ")
    }
    
    var selectedFolderStringValue: String {
        selectedFolder == nil ? "None" : selectedFolder!.name
    }
    
    var navigationBarTitle: String {
        switch configuration {
        case .edit(_):
            return "Update URL"
        case .new:
            return "New URL"
        }
    }
    
    var buttonText: String {
        switch configuration {
        case .edit(_):
            return "Update URL"
        case .new:
            return "Add URL"
        }
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
                editedLink.setValue(self.urlTextField.text, forKey: "url")
                editedLink.setValue(self.noteTextView.text, forKey: "note")
                editedLink.setValue(true, forKey: "unread")
                editedLink.setValue(self.selectedFolder, forKey: "group")
                editedLink.setValue(Set(self.selectedTags), forKey: "tags")
                
                // TODO this should only run when url is changed
                editedLink.loadMetaData()
                
            case .new:
                let newLink = Link(context: self.context)
                newLink.setValue(self.urlTextField.text, forKey: "url")
                newLink.setValue(self.noteTextView.text, forKey: "note")
                newLink.setValue(nil, forKey: "imageData")
                newLink.setValue(self.selectedFolder, forKey: "group")
                newLink.setValue(Set(self.selectedTags), forKey: "tags")
                
                CoreDataStack.shared.saveContext()
                
                newLink.loadMetaData()
            }
            
            self.dismiss(animated: true)
        })
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .close, primaryAction: UIAction { _ in
          self.dismiss(animated: true)
        })
        
        view.backgroundColor = .systemGroupedBackground
        
        view.addSubview(urlTextFieldLabel)
        view.addSubview(urlTextField)
        view.addSubview(noteTextViewLabel)
        view.addSubview(noteTextView)
        view.addSubview(groupsLabel)
        view.addSubview(groupsButton)
        view.addSubview(tagsLabel)
        view.addSubview(tagsButton)
        
        NSLayoutConstraint.activate([
            urlTextFieldLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            urlTextFieldLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 25),
            urlTextField.topAnchor.constraint(equalTo: urlTextFieldLabel.bottomAnchor, constant: 10),
            urlTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            urlTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
            urlTextField.heightAnchor.constraint(equalToConstant: 50),
            noteTextViewLabel.topAnchor.constraint(equalTo: urlTextField.bottomAnchor, constant: 20),
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
        let view = SelectionList(selection: .init(get: { self.selectedFolder }, set: { group in self.selectedFolder = group }))
            .environment(\.managedObjectContext, CoreDataStack.shared.managedContext)
        
        navigationController?.pushViewController(UIHostingController(rootView: view), animated: true)
    }
    
    @objc private func showTagsMultiselectionList() {
        let view = MultipleSelectionList(selections: selectedTags, selectedTags: .init(get: { self.selectedTags }, set: { tags in self.selectedTags = tags }))
            .environment(\.managedObjectContext, CoreDataStack.shared.managedContext)
        
        navigationController?.pushViewController(UIHostingController(rootView: view), animated: true)
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
