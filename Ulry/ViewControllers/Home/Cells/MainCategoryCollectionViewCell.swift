//
//  MainCategoryCollectionViewCell.swift
//  Ulry
//
//  Created by Mattia Righetti on 10/10/22.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import UIKit



class MainCategoryCollectionViewCell: BouncyCollectionViewCell {
    
    lazy var textLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.rounded(ofSize: 17, weight: .semibold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var sfsymbolImage: UIImageView = {
        let imgview = UIImageView()
        imgview.layer.cornerRadius = 10
        imgview.layer.backgroundColor = UIColor.clear.cgColor
        imgview.tintColor = .label
        imgview.translatesAutoresizingMaskIntoConstraints = false
        return imgview
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(textLabel)
        contentView.addSubview(sfsymbolImage)

        layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        layer.borderWidth = 2
        layer.cornerRadius = 15
        clipsToBounds = true

        NSLayoutConstraint.activate([
            sfsymbolImage.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            sfsymbolImage.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            
            textLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -15),
            textLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(with category: Category) {
        backgroundColor = category.cellContent.backgroundColor
        textLabel.text = category.cellContent.title
        
        if let icon = category.cellContent.icon {
            sfsymbolImage.image = UIImage(systemName: icon)
        }
    }

    override func prepareForReuse() {
        textLabel.text = nil
        sfsymbolImage.image = nil
    }
}
