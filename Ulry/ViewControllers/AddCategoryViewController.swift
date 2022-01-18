//
//  AddCategoryViewController.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/18/22.
//

import UIKit
import SwiftUI

struct DefaultColorPickerView: View {
    @State var selected: Color? = nil
    @Binding var selectedColor: UIColor
    var customAction: (() -> Void)? = nil
    
    var colors: [Color] = [
        .flatDeepLilac, .flatBlueSmoke, .flatGreen, .flatShakespeare,
        .lightRed, .flatRaven, .flatBlue, .flatHurricane, .flatOrange
    ]
    
    var body: some View {
        VStack {
            LazyHGrid(rows: Array(repeating: .init(.flexible()), count: 2), spacing: 30.0) {
                ForEach(colors, id: \.self) { color in
                    color
                        .clipShape(Circle())
                        .frame(minWidth: 40)
                        .onTapGesture {
                            selected = color
                            selectedColor = UIColor(hex: color.toHex!)!
                        }
                        .modifier(OverlayModifier(select: color == selected))
                }
                
                Color.gray
                    .clipShape(Circle())
                    .frame(minWidth: 40)
                    .overlay(Image(systemName: "ellipsis"))
                    .onTapGesture {
                        selected = nil
                        customAction?()
                    }
            }
        }
    }
    
    struct OverlayModifier: ViewModifier {
        var select: Bool = false
        
        func body(content: Content) -> some View {
            if select {
                content
                    .overlay(
                        Circle()
                            .stroke(lineWidth: 3.0)
                            .foregroundColor(.blue)
                            .frame(width: 50)
                    )
            } else {
                content
            }
        }
    }
}

struct DefaultIconPicker: View {
    @State var selected: String? = nil
    @Binding var selectedGlyph: String
    var customAction: (() -> Void)?
    
    var glyphs = SFSymbols.all[0...13]
    let gradient = Gradient(stops: [
        .init(color: Color(uiColor: .systemGray), location: 0),
        .init(color: Color(uiColor: .systemGray2), location: 0.8)
    ])
    
    var body: some View {
        VStack {
            LazyHGrid(rows: Array(repeating: .init(.flexible()), count: 3), spacing: 30.0) {
                ForEach(glyphs, id: \.self) { glyph in
                    ZStack {
                        LinearGradient(gradient: gradient, startPoint: .top, endPoint: .bottom)
                            .frame(minWidth: 40)
                            .clipShape(Circle())
                            .onTapGesture {
                                selected = glyph
                                selectedGlyph = glyph
                            }
                            .modifier(OverlayModifier(select: glyph == selected))
                        Image(systemName: glyph)
                    }
                }
                
                ZStack {
                    LinearGradient(gradient: gradient, startPoint: .top, endPoint: .bottom)
                        .frame(minWidth: 40)
                        .clipShape(Circle())
                        .onTapGesture {
                            selected = nil
                            customAction?()
                        }
                    Image(systemName: "ellipsis")
                }
            }
        }
    }
    
    struct OverlayModifier: ViewModifier {
        var select: Bool = false
        
        func body(content: Content) -> some View {
            if select {
                content
                    .overlay(
                        Circle()
                            .stroke(lineWidth: 3.0)
                            .foregroundColor(.blue)
                            .frame(width: 50)
                    )
            } else {
                content
            }
        }
    }
}

struct SFSymbolsList: View {
    @Environment (\.dismiss) var dismiss
    @State var selected: String? = nil
    @Binding var selectedGlyph: String
    
    var body: some View {
        List {
            ForEach(SFSymbols.all, id: \.self) { symbol in
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
        view.backgroundColor = .white.withAlphaComponent(0.1)
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
        view.layer.shadowRadius = 10.0
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.5
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
        textField.backgroundColor = .white.withAlphaComponent(0.1)
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
        view.backgroundColor = .white.withAlphaComponent(0.1)
        view.layer.cornerRadius = 15
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var backgroundColor3: UIView = {
        let view = UIView()
        view.backgroundColor = .white.withAlphaComponent(0.1)
        view.layer.cornerRadius = 15
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var colorSelectionGrid: UIHostingController<DefaultColorPickerView> = {
        let view = DefaultColorPickerView(
            selected: Color(uiColor: color),
            selectedColor: .init(get: { self.color }, set: { color in self.color = color }),
            customAction: { [unowned self] in
                self.showColorPicker()
            }
        )
        
        let vc = UIHostingController(rootView: view)
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        vc.view.backgroundColor = .clear
        
        return vc
    }()
    
    lazy var iconSelectionGrid: UIHostingController<DefaultIconPicker> = {
        let view = DefaultIconPicker(
            selected: nil,
            selectedGlyph: .init(get: { self.glyph }, set: { glyph in self.glyph = glyph }),
            customAction: { [unowned self] in
                self.showIconPicker()
            }
        )
        
        let vc = UIHostingController(rootView: view)
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        vc.view.backgroundColor = .clear
        
        return vc
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.rightBarButtonItem = UIBarButtonItem(systemItem: .save, primaryAction: UIAction { [unowned self] _ in
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
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .close, primaryAction: UIAction { _ in
          self.dismiss(animated: true)
        })
        
        configure()
        
        view.backgroundColor = .systemBackground
        view.addSubview(backgroundView)
        view.addSubview(colorBackgroundView)
        view.addSubview(titleTextField)
        
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
        ])
        
        setupForConfiguration()
    }
    
    private func setupForConfiguration() {
        switch configuration {
        case .tag, .editTag(_):
            view.addSubview(backgroundColor2)
            
            colorSelectionGrid.add(self, frame: .zero)
            backgroundColor2.addSubview(colorSelectionGrid.view)
            
            NSLayoutConstraint.activate([
                backgroundColor2.topAnchor.constraint(equalTo: backgroundView.bottomAnchor, constant: 25),
                backgroundColor2.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
                backgroundColor2.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
                colorSelectionGrid.view.topAnchor.constraint(equalTo: backgroundColor2.topAnchor, constant: 10),
                colorSelectionGrid.view.leadingAnchor.constraint(equalTo: backgroundColor2.leadingAnchor, constant: 10),
                colorSelectionGrid.view.trailingAnchor.constraint(equalTo: backgroundColor2.trailingAnchor, constant: -10),
                backgroundColor2.bottomAnchor.constraint(equalTo: colorSelectionGrid.view.bottomAnchor, constant: 10),
            ])
        case .group, .editGroup(_):
            view.addSubview(backgroundColor2)
            view.addSubview(backgroundColor3)
            view.addSubview(glyphLabel)
            
            colorSelectionGrid.add(self, frame: .zero)
            iconSelectionGrid.add(self, frame: .zero)
            
            backgroundColor2.addSubview(colorSelectionGrid.view)
            backgroundColor3.addSubview(iconSelectionGrid.view)
            
            NSLayoutConstraint.activate([
                glyphLabel.centerXAnchor.constraint(equalTo: colorBackgroundView.centerXAnchor),
                glyphLabel.centerYAnchor.constraint(equalTo: colorBackgroundView.centerYAnchor),
                backgroundColor2.topAnchor.constraint(equalTo: backgroundView.bottomAnchor, constant: 25),
                backgroundColor2.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
                backgroundColor2.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
                colorSelectionGrid.view.topAnchor.constraint(equalTo: backgroundColor2.topAnchor, constant: 10),
                colorSelectionGrid.view.leadingAnchor.constraint(equalTo: backgroundColor2.leadingAnchor, constant: 10),
                colorSelectionGrid.view.trailingAnchor.constraint(equalTo: backgroundColor2.trailingAnchor, constant: -10),
                backgroundColor2.bottomAnchor.constraint(equalTo: colorSelectionGrid.view.bottomAnchor, constant: 10),
                backgroundColor3.topAnchor.constraint(equalTo: backgroundColor2.bottomAnchor, constant: 25),
                backgroundColor3.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
                backgroundColor3.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
                iconSelectionGrid.view.topAnchor.constraint(equalTo: backgroundColor3.topAnchor, constant: 10),
                iconSelectionGrid.view.leadingAnchor.constraint(equalTo: backgroundColor3.leadingAnchor, constant: 10),
                iconSelectionGrid.view.trailingAnchor.constraint(equalTo: backgroundColor3.trailingAnchor, constant: -10),
                backgroundColor3.bottomAnchor.constraint(equalTo: iconSelectionGrid.view.bottomAnchor, constant: 10),
            ])
        case .none:
            break
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
        self.navigationController?.pushViewController(vc, animated: true)
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
