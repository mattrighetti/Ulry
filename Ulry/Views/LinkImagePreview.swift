//
//  LinkImagePreview.swift
//  Ulry
//
//  Created by Mattia Righetti on 10/15/22.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import UIKit

class LinkImagePreview: UIView {
    enum Kind {
        case image(UIImage)
        case color(UIColor, String)
    }
    
    var kind: Kind? = nil {
        didSet {
            switch kind {
            case .color(let color, let letter):
                image.backgroundColor = color
                urlLetterLabel.text = letter
                image.image = nil
            case .image(let uiimage):
                image.image = uiimage
                image.backgroundColor = nil
                urlLetterLabel.text = nil
            default:
                fatalError()
            }
        }
    }

    var action: (() -> Void)?
    
    lazy var image: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 10
        imageView.contentMode = .scaleAspectFill
        imageView.isUserInteractionEnabled = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    lazy var urlLetterLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.rounded(ofSize: 23, weight: .black)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        image.clipsToBounds = true

        addSubview(image)
        addSubview(urlLetterLabel)
        
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onInfoButtonPressed)))
        
        NSLayoutConstraint.activate([
            urlLetterLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            urlLetterLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        image.frame = self.bounds
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func onInfoButtonPressed() {
        UIView.animate(withDuration: 0.1) {
            self.transform = .identity.scaledBy(x: 1.5, y: 1.5)
        }

        UIView.animate(withDuration: 0.1) {
            self.transform = .identity
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) {
            self.action?()
        }
    }
}
