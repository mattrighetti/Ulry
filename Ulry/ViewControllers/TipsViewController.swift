//
//  TipsViewController.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/21/22.
//

import UIKit
import StoreKit

class TipsViewController: UIViewController {
    let manager = IAPManager.shared
    
    lazy var glyphSign: UIImageView = {
        let configuration = UIImage.SymbolConfiguration.init(paletteColors: [.systemRed])
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "app.gift.fill", withConfiguration: configuration)!
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    lazy var blur: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .systemThinMaterialDark)
        let visualView = UIVisualEffectView(effect: blurEffect)
        visualView.layer.opacity = 0
        return visualView
    }()
    
    lazy var backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .tertiarySystemGroupedBackground
        view.layer.cornerRadius = 20
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var discoseButton: UIButton = {
        let button = UIButton(type: .close)
        button.backgroundColor = .systemFill
        button.layer.cornerRadius = 15
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Tip Jar"
        label.font = UIFont.rounded(ofSize: 20, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "If you feel extra nice today and would like to support Ulry development, go ahead and offer me a coffe!"
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var smallTipLabel: UILabel = {
        let label = UILabel()
        label.text = "☕️ Coffee Tip"
        label.font = UIFont.rounded(ofSize: 16, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var mediumTipLabel: UILabel = {
        let label = UILabel()
        label.text = "🍩 Donut Tip"
        label.font = UIFont.rounded(ofSize: 16, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var bigTipLabel: UILabel = {
        let label = UILabel()
        label.text = "🍕 Pizza Tip"
        label.font = UIFont.rounded(ofSize: 16, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var extraTipLabel: UILabel = {
        let label = UILabel()
        label.text = "🔥 Super Tip"
        label.font = UIFont.rounded(ofSize: 16, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var smallTipButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.showsActivityIndicator = true
        let button = UIButton(configuration: configuration)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    lazy var mediumTipButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.showsActivityIndicator = true
        let button = UIButton(configuration: configuration)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    lazy var bigTipButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.showsActivityIndicator = true
        let button = UIButton(configuration: configuration)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    lazy var extraTipButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.showsActivityIndicator = true
        let button = UIButton(configuration: configuration)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    func buttonTextWithFont(_ string: String) -> AttributedString {
        return AttributedString(
            NSAttributedString(string: string, attributes: [.font: UIFont.rounded(ofSize: 14, weight: .semibold)])
        )
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Task.init(priority: .high) {
            let products = try! await manager.fetchProducts()
            setupButtons(with: products)
        }
        
        view.backgroundColor = .clear
        
        blur.frame = view.bounds
        
        view.addSubview(blur)
        view.addSubview(backgroundView)
        backgroundView.addSubview(glyphSign)
        backgroundView.addSubview(discoseButton)
        backgroundView.addSubview(titleLabel)
        backgroundView.addSubview(descriptionLabel)
        backgroundView.addSubview(smallTipLabel)
        backgroundView.addSubview(mediumTipLabel)
        backgroundView.addSubview(bigTipLabel)
        backgroundView.addSubview(extraTipLabel)
        backgroundView.addSubview(smallTipButton)
        backgroundView.addSubview(mediumTipButton)
        backgroundView.addSubview(bigTipButton)
        backgroundView.addSubview(extraTipButton)
        
        let buttonWidth: CGFloat = 80
        let buttonHeight: CGFloat = 40
        
        NSLayoutConstraint.activate([
            backgroundView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            backgroundView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            backgroundView.widthAnchor.constraint(equalToConstant: UIScreen.screenWidth - 60),
            backgroundView.heightAnchor.constraint(equalToConstant: UIScreen.screenWidth - 10),
            
            glyphSign.centerYAnchor.constraint(equalTo: backgroundView.topAnchor),
            glyphSign.centerXAnchor.constraint(equalTo: backgroundView.centerXAnchor),
            glyphSign.widthAnchor.constraint(equalToConstant: 60),
            glyphSign.heightAnchor.constraint(equalToConstant: 60),
            
            discoseButton.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: 15),
            discoseButton.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -15),
            discoseButton.heightAnchor.constraint(equalToConstant: 30),
            discoseButton.widthAnchor.constraint(equalToConstant: 30),
            
            titleLabel.centerXAnchor.constraint(equalTo: backgroundView.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: 40),
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            descriptionLabel.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: 15),
            descriptionLabel.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -15),
            
            smallTipButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 15),
            smallTipButton.trailingAnchor.constraint(equalTo: descriptionLabel.trailingAnchor),
            smallTipButton.widthAnchor.constraint(equalToConstant: buttonWidth),
            smallTipButton.heightAnchor.constraint(equalToConstant: buttonHeight),
            mediumTipButton.topAnchor.constraint(equalTo: smallTipButton.bottomAnchor, constant: 10),
            mediumTipButton.trailingAnchor.constraint(equalTo: descriptionLabel.trailingAnchor),
            mediumTipButton.widthAnchor.constraint(equalToConstant: buttonWidth),
            mediumTipButton.heightAnchor.constraint(equalToConstant: buttonHeight),
            bigTipButton.topAnchor.constraint(equalTo: mediumTipButton.bottomAnchor, constant: 10),
            bigTipButton.trailingAnchor.constraint(equalTo: descriptionLabel.trailingAnchor),
            bigTipButton.widthAnchor.constraint(equalToConstant: buttonWidth),
            bigTipButton.heightAnchor.constraint(equalToConstant: buttonHeight),
            extraTipButton.topAnchor.constraint(equalTo: bigTipButton.bottomAnchor, constant: 10),
            extraTipButton.trailingAnchor.constraint(equalTo: descriptionLabel.trailingAnchor),
            extraTipButton.widthAnchor.constraint(equalToConstant: buttonWidth),
            extraTipButton.heightAnchor.constraint(equalToConstant: buttonHeight),
            
            smallTipLabel.centerYAnchor.constraint(equalTo: smallTipButton.centerYAnchor),
            smallTipLabel.leadingAnchor.constraint(equalTo: descriptionLabel.leadingAnchor),
            mediumTipLabel.centerYAnchor.constraint(equalTo: mediumTipButton.centerYAnchor),
            mediumTipLabel.leadingAnchor.constraint(equalTo: descriptionLabel.leadingAnchor),
            bigTipLabel.centerYAnchor.constraint(equalTo: bigTipButton.centerYAnchor),
            bigTipLabel.leadingAnchor.constraint(equalTo: descriptionLabel.leadingAnchor),
            extraTipLabel.centerYAnchor.constraint(equalTo: extraTipButton.centerYAnchor),
            extraTipLabel.leadingAnchor.constraint(equalTo: descriptionLabel.leadingAnchor),
        ])
    }
    
    func setupButtons(with products: [Product]) {
        setup(button: smallTipButton, with: products[0])
        setup(button: mediumTipButton, with: products[1])
        setup(button: bigTipButton, with: products[2])
        setup(button: extraTipButton, with: products[3])
    }
    
    var buttonIsSelected = false
    
    func setup(button: UIButton, with product: Product) {
        button.configuration?.showsActivityIndicator = false
        button.configuration?.attributedTitle = buttonTextWithFont(product.displayPrice)
        button.addAction(UIAction { _ in
            Task.init { [weak self] in
                button.configuration?.showsActivityIndicator = true
                button.configuration?.title = ""
                
                do {
                    let _ = try await self?.manager.purchase(product)
                    self?.showThankYou()
                } catch {
                    print("error: \(error)")
                }
                
                button.configuration?.showsActivityIndicator = false
                button.configuration?.attributedTitle = self?.buttonTextWithFont(product.displayPrice)
            }
        }, for: .touchUpInside)
    }
    
    func showThankYou() {
        let ac = UIAlertController(title: "Thank you!", message: nil, preferredStyle: .alert)
        let ok = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
        ac.addAction(ok)
        present(ac, animated: false, completion: nil)
    }
}
