//
//  UrlTextFieldAccessoryView.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/20/22.
//

import UIKit

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
        var configuration = UIButton.Configuration.bordered()
        configuration.baseForegroundColor = .white
        configuration.attributedTitle = AttributedString("www", attributes: AttributeContainer([
            NSAttributedString.Key.font: UIFont.monospacedSystemFont(ofSize: 13, weight: .bold)
        ]))
        
        let button = UIButton(configuration: configuration, primaryAction: nil)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    lazy var httpsButton: UIButton = {
        var configuration = UIButton.Configuration.bordered()
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
        view.axis = .horizontal
        view.alignment = .center
        view.spacing = 5.0
        view.distribution = .fillProportionally
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .secondarySystemBackground
        contentMode = .center
        isScrollEnabled = true
        alwaysBounceHorizontal = true
        translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(horizontalStackView)
        horizontalStackView.addArrangedSubview(doneButton)
        horizontalStackView.addArrangedSubview(pasteButton)
        horizontalStackView.addArrangedSubview(httpsButton)
        horizontalStackView.addArrangedSubview(wwwButton)
        
        NSLayoutConstraint.activate([
            horizontalStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            horizontalStackView.leadingAnchor.constraint(equalTo: leadingAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
