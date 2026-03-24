//
//  MainCategoryCollectionViewCell.swift
//  Ulry
//
//  Created by Mattia Righetti on 10/10/22.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import UIKit

class MainCategoryCollectionViewCell: BouncyCollectionViewCell {

    private let gradientLayer = CAGradientLayer()

    lazy var sfsymbolImage: UIImageView = {
        let imgview = UIImageView()
        imgview.tintColor = .white
        imgview.contentMode = .scaleAspectFit
        imgview.translatesAutoresizingMaskIntoConstraints = false
        return imgview
    }()

    lazy var textLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.rounded(ofSize: 15, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.cornerRadius = 22
        contentView.layer.insertSublayer(gradientLayer, at: 0)
        contentView.layer.cornerRadius = 22
        contentView.layer.masksToBounds = true

        contentView.addSubview(sfsymbolImage)
        contentView.addSubview(textLabel)

        NSLayoutConstraint.activate([
            sfsymbolImage.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            sfsymbolImage.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -10),
            sfsymbolImage.widthAnchor.constraint(equalToConstant: 34),
            sfsymbolImage.heightAnchor.constraint(equalToConstant: 34),

            textLabel.topAnchor.constraint(equalTo: sfsymbolImage.bottomAnchor, constant: 8),
            textLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            textLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = contentView.bounds
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: 22).cgPath
    }

    func update(with category: Category) {
        let baseColor = category.cellContent.backgroundColor
        gradientLayer.colors = baseColor.gradientColors

        layer.shadowColor = baseColor.cgColor
        layer.shadowOpacity = 0.40
        layer.shadowOffset = CGSize(width: 0, height: 6)
        layer.shadowRadius = 12

        textLabel.text = category.cellContent.title

        if let icon = category.cellContent.icon {
            let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .semibold)
            sfsymbolImage.image = UIImage(systemName: icon, withConfiguration: config)
        }
    }

    override func prepareForReuse() {
        textLabel.text = nil
        sfsymbolImage.image = nil
    }
}
