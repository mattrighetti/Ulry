//
//  UrlTextFieldAccessoryView.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/20/22.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import UIKit

class UrlTextFieldAccessoryView: UIScrollView {
    
    struct Configuration {
        let withWwwButton: Bool
        let withHttpsButton: Bool
        
        public static func plain() -> Self {
            return .init(withWwwButton: false, withHttpsButton: false)
        }
        
        public static func complete() -> Self {
            return .init(withWwwButton: true, withHttpsButton: true)
        }
    }
    
    lazy var doneButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        configuration.baseForegroundColor = .label
        configuration.attributedTitle = AttributedString("Done", attributes: AttributeContainer([
            NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 15)
        ]))
        
        let button = UIButton(configuration: configuration, primaryAction: nil)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    lazy var wwwButton: UIButton = {
        var configuration = UIButton.Configuration.bordered()
        configuration.baseForegroundColor = .label
        configuration.attributedTitle = AttributedString("www", attributes: AttributeContainer([
            NSAttributedString.Key.font: UIFont.monospacedSystemFont(ofSize: 13, weight: .light)
        ]))
        
        let button = UIButton(configuration: configuration, primaryAction: nil)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    lazy var httpsButton: UIButton = {
        var configuration = UIButton.Configuration.bordered()
        configuration.baseForegroundColor = .label
        configuration.attributedTitle = AttributedString("https", attributes: AttributeContainer([
            NSAttributedString.Key.font: UIFont.monospacedSystemFont(ofSize: 13, weight: .light)
        ]))
        
        let button = UIButton(configuration: configuration, primaryAction: nil)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    lazy var pasteButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        configuration.baseForegroundColor = .label
        configuration.image = UIImage(systemName: "doc.on.clipboard", withConfiguration: UIImage.SymbolConfiguration(weight: .light))
        configuration.imagePlacement = .leading
        configuration.buttonSize = .small
        
        let button = UIButton(configuration: configuration, primaryAction: nil)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    lazy var horizontalStackView: UIStackView = {
        let view = UIStackView()
        view.spacing = 5.0
        view.axis = .horizontal
        view.alignment = .center
        view.distribution = .fillProportionally
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    init(frame: CGRect, withConfiguration configuration: Configuration) {
        super.init(frame: frame)
                
        contentMode = .center
        isScrollEnabled = true
        alwaysBounceHorizontal = true
        backgroundColor = .secondarySystemBackground
        
        addSubview(horizontalStackView)
        setup(withConfiguration: configuration)
    }
    
    func setup(withConfiguration configuration: Configuration) {
        horizontalStackView.addArrangedSubview(doneButton)
        horizontalStackView.addArrangedSubview(pasteButton)
        
        if configuration.withHttpsButton {
            horizontalStackView.addArrangedSubview(httpsButton)
        }
        
        if configuration.withWwwButton {
            horizontalStackView.addArrangedSubview(wwwButton)
        }
        
        NSLayoutConstraint.activate([
            horizontalStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            horizontalStackView.leadingAnchor.constraint(equalTo: leadingAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
