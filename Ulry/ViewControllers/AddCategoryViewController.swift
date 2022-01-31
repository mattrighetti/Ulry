//
//  AddCategoryViewController.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/18/22.
//

import UIKit
import SwiftUI

struct SFSymbolsList: View {
    @Environment (\.dismiss) var dismiss
    
    @State private var searchText: String = ""
    @State var selected: String? = nil
    @Binding var selectedGlyph: String
    
    var body: some View {
        NavigationView {
            List {
                ForEach(SFSymbols.all.filter {
                    if !searchText.isEmpty {
                        return $0.lowercased().contains(searchText.lowercased())
                    }
                    return true
                }, id: \.self) { symbol in
                    Button(action: {
                        self.selected = symbol
                        self.selectedGlyph = symbol
                        self.dismiss()
                    }) {
                        HStack {
                            Image(systemName: symbol)
                            Text(symbol)
                            Spacer()
                            if selected == symbol {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
            }
            
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    ButtonClose(action: { self.dismiss() })
                }
            }
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
    }
}

class AddCategoryViewController: UIViewController {
    enum PickerMode: Equatable, RawRepresentable {
        case group
        case editGroup(Group)
        case tag
        case editTag(Tag)
        
        public init?(rawValue: String) {
            return nil
        }
        
        public typealias RawValue = String
        
        public var rawValue: RawValue {
            switch self {
            case .group:
                return "group"
            case .editGroup(_):
                return "group"
            case .tag:
                return "tag"
            case .editTag(_):
                return "tag"
            }
        }
    }
    
    let context = CoreDataStack.shared.managedContext
    var configuration: PickerMode? = .tag
    
    var color: UIColor = UIColor.random {
        didSet {
            self.colorBackgroundView.backgroundColor = color
        }
    }
    
    var glyph: String = SFSymbols.all[Int.random(in: 1...SFSymbols.all.count)] {
        didSet {
            let attachment = NSTextAttachment()
            attachment.image = UIImage(systemName: glyph, withConfiguration: UIImage.SymbolConfiguration(pointSize: 50, weight: .bold, scale: .small))?.withTintColor(.white)
            let imageString = NSMutableAttributedString(attachment: attachment)
            glyphLabel.attributedText = imageString
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
        attachment.image = UIImage(systemName: glyph, withConfiguration: UIImage.SymbolConfiguration(pointSize: 50, weight: .bold, scale: .small))?.withTintColor(.white)
        
        let imageString = NSMutableAttributedString(attachment: attachment)
        let label = UILabel()
        label.attributedText = imageString
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
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showColorPicker)))
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
        
        button.addAction(UIAction { _ in
            self.showColorPicker()
        }, for: .touchUpInside)
        
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
        
        button.addAction(UIAction { _ in
            self.showIconPicker()
        }, for: .touchUpInside)
        
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
            guard let text = titleTextField.text, !text.isEmpty else {
                let alert = UIAlertController(title: "No name", message: "Please make sure to insert a valid name", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                present(alert, animated: true)
                return
            }
            
            switch configuration {
            case .group:
                let group = Group(context: context)
                group.setValue(UUID(), forKey: "id")
                group.setValue(text, forKey: "name")
                group.setValue(color.toHex!, forKey: "colorHex")
                group.setValue(glyph, forKey: "iconName")
                
            case .editGroup(let group):
                group.setValue(text, forKey: "name")
                group.setValue(color.toHex!, forKey: "colorHex")
                group.setValue(glyph, forKey: "iconName")
                
            case .tag:
                let tag = Tag(context: context)
                tag.setValue(UUID(), forKey: "id")
                tag.setValue(text, forKey: "name")
                tag.setValue(color.toHex!, forKey: "colorHex")
                
            case .editTag(let tag):
                tag.setValue(text, forKey: "name")
                tag.setValue(color.toHex!, forKey: "colorHex")
            case .none:
                break
            }
            
            CoreDataStack.shared.saveContext()
            
            self.dismiss(animated: true)
        })
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.rightBarButtonItem = rightBarButtonItem
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .close, primaryAction: UIAction { _ in
          self.dismiss(animated: true)
        })
        
        configure()
        
        view.backgroundColor = .systemGroupedBackground
        
        view.addSubview(backgroundView)
        view.addSubview(colorBackgroundView)
        view.addSubview(titleTextField)
        view.addSubview(buttonStackView)
        buttonStackView.addArrangedSubview(chooseColorButton)
        
        setup()
        
        showKeyboard()
    }
    
    private func setup() {
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
            buttonStackView.addArrangedSubview(chooseIconButton)
            
            view.addSubview(glyphLabel)
            NSLayoutConstraint.activate([
                glyphLabel.centerXAnchor.constraint(equalTo: colorBackgroundView.centerXAnchor),
                glyphLabel.centerYAnchor.constraint(equalTo: colorBackgroundView.centerYAnchor)
            ])
        default: break
        }
    }
    
    private func configure() {
        switch configuration {
        case .editGroup(let group):
            self.titleTextField.text = group.name
            self.color = UIColor(hex: group.colorHex)!
            self.glyph = group.iconName
            break
        case .editTag(let tag):
            self.titleTextField.text = tag.name
            self.color = UIColor(hex: tag.colorHex)!
            break
        case .group, .tag, .none:
            break
        }
    }
    
    @objc private func showColorPicker() {
        let picker = UIColorPickerViewController()
        picker.delegate = self
        picker.supportsAlpha = false
        present(picker, animated: true)
    }
    
    @objc private func showIconPicker() {
        let view = SFSymbolsList(selected: glyph, selectedGlyph: .init(get: { self.glyph }, set: { glypn in self.glyph = glypn }))
        let vc = UIHostingController(rootView: view)
        present(vc, animated: true)
    }
    
    private func showKeyboard() {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) { [weak self] in
            self?.titleTextField.becomeFirstResponder()
        }
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
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
        
    }
}

struct AddCategoryViewControlleRepresentable: UIViewControllerRepresentable {
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
    
    var mode: AddCategoryViewController.PickerMode = .tag
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let view = AddCategoryViewController()
        let vc = UINavigationController(rootViewController: view)
        view.configuration = mode
        return vc
    }
}
