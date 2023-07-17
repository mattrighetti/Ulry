//
//  AddCategoryViewController.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/18/22.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import UIKit
import Links
import SwiftUI
import Account

class AddCategoryViewController: UIViewController {
    
    enum Mode: Equatable {
        case group
        case editGroup(Links.Group)
        case tag
        case editTag(Links.Tag)
    }

    var account: Account!

    var configuration: Mode = .tag
    
    var color: UIColor = UIColor.random {
        didSet {
            self.colorBackgroundView.backgroundColor = color
        }
    }
    
    var glyph: String = SFSymbols.all[Int.random(in: 1...SFSymbols.all.count)] {
        didSet {
            let attachment = NSTextAttachment()
            let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: 50, weight: .bold, scale: .small)
            attachment.image = UIImage(systemName: glyph, withConfiguration: symbolConfiguration)?.withTintColor(.white)
            glyphLabel.attributedText = NSMutableAttributedString(attachment: attachment)
        }
    }
    
    lazy var backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = 15
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var glyphLabel: UILabel = {
        let attachment = NSTextAttachment()
        let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: 50, weight: .bold, scale: .small)
        attachment.image = UIImage(systemName: glyph, withConfiguration: symbolConfiguration)?.withTintColor(.white)
        
        let label = UILabel()
        label.attributedText = NSMutableAttributedString(attachment: attachment)
        label.textColor = .white
        label.sizeToFit()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var colorBackgroundView: UIView = {
        let view = UIView()
        view.layer.shadowRadius = 6.0
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.3
        view.layer.shadowOffset = CGSize(width: 0.0, height: 5.0)
        view.backgroundColor = color
        view.layer.cornerRadius = 50
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var titleTextField: UITextField = {
        let textField = UITextField()
        textField.delegate = self
        textField.keyboardType = .asciiCapable
        textField.backgroundColor = .tertiarySystemGroupedBackground
        textField.layer.cornerRadius = 15
        textField.placeholder = "Name"
        textField.clearButtonMode = .whileEditing
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15.0, height: textField.frame.height))
        textField.leftViewMode = .always
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    lazy var backgroundColor2: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = 15
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var backgroundColor3: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = 15
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var chooseColorButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.title = "Change color"
        configuration.image = UIImage(systemName: "chevron.right")
        configuration.baseForegroundColor = .systemBlue
        configuration.baseBackgroundColor = .secondarySystemGroupedBackground
        configuration.imagePlacement = .trailing
        configuration.imagePadding = 10.0
        configuration.cornerStyle = .large
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 15, leading: 0, bottom: 15, trailing: 0)
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(scale: .small)
        
        let button = UIButton()
        button.configuration = configuration
        button.addAction(UIAction { [unowned self] _ in self.showColorPicker() }, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    lazy var chooseIconButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.title = "Change icon"
        configuration.image = UIImage(systemName: "chevron.right")
        configuration.baseForegroundColor = .systemBlue
        configuration.baseBackgroundColor = .secondarySystemGroupedBackground
        configuration.imagePlacement = .trailing
        configuration.imagePadding = 10.0
        configuration.cornerStyle = .large
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 15, leading: 0, bottom: 15, trailing: 0)
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(scale: .small)
        
        let button = UIButton()
        button.configuration = configuration
        button.addAction(UIAction { [unowned self] _ in self.showIconPicker() }, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    lazy var buttonStackView: UIStackView = {
        let stackview = UIStackView()
        stackview.axis = .horizontal
        stackview.alignment = .fill
        stackview.distribution = .fillEqually
        stackview.spacing = 10.0
        stackview.translatesAutoresizingMaskIntoConstraints = false
        return stackview
    }()
    
    lazy var rightBarButtonItem: UIBarButtonItem = {
        UIBarButtonItem(systemItem: .save, primaryAction: UIAction { [unowned self] _ in
            guard self.checkTitleTextFieldInputValidity() else { return }
            self.handleSave()
        })
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.rightBarButtonItem = rightBarButtonItem
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .close, primaryAction: UIAction { [unowned self] _ in
            dismiss(animated: true)
        })
        
        view.backgroundColor = .systemGroupedBackground
        
        setup()
        configure()
        showKeyboard()
    }
    
    private func setup() {
        view.addSubview(backgroundView)
        view.addSubview(colorBackgroundView)
        view.addSubview(titleTextField)
        view.addSubview(buttonStackView)
        
        switch configuration {
        case .group, .editGroup(_):
            buttonStackView.addArrangedSubview(chooseColorButton)
            buttonStackView.addArrangedSubview(chooseIconButton)
            view.addSubview(glyphLabel)
        case .tag, .editTag(_):
            buttonStackView.addArrangedSubview(chooseColorButton)
        }
        
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
            colorBackgroundView.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: 25),
            colorBackgroundView.centerXAnchor.constraint(equalTo: backgroundView.centerXAnchor),
            colorBackgroundView.heightAnchor.constraint(equalToConstant: 100),
            colorBackgroundView.widthAnchor.constraint(equalToConstant: 100),
            titleTextField.topAnchor.constraint(equalTo: colorBackgroundView.bottomAnchor, constant: 25),
            titleTextField.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: 15),
            titleTextField.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -15),
            titleTextField.heightAnchor.constraint(equalToConstant: 50),
            backgroundView.bottomAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: 25),
            buttonStackView.topAnchor.constraint(equalTo: backgroundView.bottomAnchor, constant: 15),
            buttonStackView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor),
            buttonStackView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor),
            buttonStackView.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        switch configuration {
        case .group, .editGroup(_):
            NSLayoutConstraint.activate([
                glyphLabel.centerXAnchor.constraint(equalTo: colorBackgroundView.centerXAnchor),
                glyphLabel.centerYAnchor.constraint(equalTo: colorBackgroundView.centerYAnchor)
            ])
        default: break
        }
    }
    
    private func configure() {
        if case .editGroup(let group) = configuration {
            guard let groupColor = UIColor(hex: group.colorHex) else { fatalError() }
            titleTextField.text = group.name
            color = groupColor
            glyph = group.iconName
        }
        
        if case .editTag(let tag) = configuration {
            guard let tagColor = UIColor(hex: tag.colorHex) else { fatalError() }
            titleTextField.text = tag.name
            color = tagColor
        }
    }
    
    @objc private func showColorPicker() {
        let picker = UIColorPickerViewController()
        picker.delegate = self
        picker.supportsAlpha = false
        present(picker, animated: true)
    }
    
    @objc private func showIconPicker() {
        let viewController = SFSymbolsCollectionView()
        viewController.delegate = self
        let navController = UINavigationController(rootViewController: viewController)
        present(navController, animated: true)
    }
    
    private func showKeyboard() {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) { [unowned self] in
            self.titleTextField.becomeFirstResponder()
        }
    }

    private func checkTitleTextFieldInputValidity() -> Bool {
        // Must not be empty
        titleTextField.text = titleTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let input = titleTextField.text, !input.isEmpty else {
            showError(title: "Field is empty", message: "Fill out all the fields to continue")
            return false
        }

        switch configuration {
        case .tag:
            if try! account.existsTag(with: input) {
                showError(title: "Duplicate tag", message: "A tag with the name \(input) already exists")
                return false
            }
        case .group:
            if try! account.existsGroup(with: input) {
                showError(title: "Duplicate group", message: "A group with the name \(input) already exists")
                return false
            }
        case .editTag(let tag):
            if tag.name != input && (try! account.existsTag(with: input)) {
                showError(title: "Duplicate tag", message: "A tag with the name \(input) already exists")
                return false
            }
        case .editGroup(let group):
            if group.name != input && (try! account.existsGroup(with: input)) {
                showError(title: "Duplicate group", message: "A group with the name \(input) already exists")
                return false
            }
        }

        return true
    }

    private func showError(title: String?, message: String?) {
        let alert = UIAlertController.okAlert(title: title, message: message)
        present(alert, animated: true)
    }
    
    private func handleSave() {
        guard let text = titleTextField.text, let colorHex = color.toHex else { fatalError() }
        
        switch configuration {
        case .group:
            let group = Group(colorHex: colorHex, iconName: glyph, name: text, links: nil)

            Task {
                await account.insert(group: group)
            }
            break
            
        case .editGroup(let group):
            group.name = text
            group.colorHex = colorHex
            group.iconName = glyph

            Task {
                await account.update(group: group)
            }
            break
            
        case .tag:
            let tag = Tag(colorHex: colorHex, name: text)

            Task {
                await account.insert(tag: tag)
            }
            break
            
        case .editTag(let tag):
            tag.name = text
            tag.colorHex = colorHex

            Task {
                await account.update(tag: tag)
            }
            break
        }
        
        self.dismiss(animated: true)
    }
}

extension AddCategoryViewController: UIColorPickerViewControllerDelegate {
    func colorPickerViewController(_ viewController: UIColorPickerViewController, didSelect color: UIColor, continuously: Bool) {
        self.color = color
    }
}

extension AddCategoryViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        textField.text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
    }
}

extension AddCategoryViewController: SFSymbolsCollectionViewDelegate {
    func sfsymbolscollectionview(_ sfsymbolscollectionview: SFSymbolsCollectionView, didSelect icon: String) {
        self.glyph = icon
    }
}

