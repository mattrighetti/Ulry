//
//  GroupCategoryCollectionViewCell.swift
//  Ulry
//
//  Created by Mattia Righetti on 10/10/22.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import UIKit

class GroupCollectionViewCell: BouncyCollectionViewCell {

    var longPressAction: (() -> Void)? = nil

    private let gradientLayer = CAGradientLayer()

    lazy var sfsymbolImage: UIImageView = {
        let imgview = UIImageView()
        imgview.tintColor = .white
        imgview.contentMode = .scaleAspectFit
        imgview.translatesAutoresizingMaskIntoConstraints = false
        return imgview
    }()

    lazy var label: UILabel = {
        let label = UILabel()
        label.font = UIFont.rounded(ofSize: 15, weight: .bold)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    lazy var chevron: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        let imgview = UIImageView(image: UIImage(systemName: "chevron.right", withConfiguration: config))
        imgview.tintColor = UIColor.white.withAlphaComponent(0.6)
        imgview.translatesAutoresizingMaskIntoConstraints = false
        return imgview
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.cornerRadius = 16
        contentView.layer.insertSublayer(gradientLayer, at: 0)
        contentView.layer.cornerRadius = 16
        contentView.layer.masksToBounds = true

        contentView.addSubview(sfsymbolImage)
        contentView.addSubview(label)
        contentView.addSubview(chevron)

        let lpr = UILongPressGestureRecognizer(target: self, action: #selector(longPressGesture))
        lpr.minimumPressDuration = 0.5
        addGestureRecognizer(lpr)

        NSLayoutConstraint.activate([
            sfsymbolImage.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 18),
            sfsymbolImage.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            sfsymbolImage.widthAnchor.constraint(equalToConstant: 22),
            sfsymbolImage.heightAnchor.constraint(equalToConstant: 22),

            label.leadingAnchor.constraint(equalTo: sfsymbolImage.trailingAnchor, constant: 14),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            label.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -8),

            chevron.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -18),
            chevron.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = contentView.bounds
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: 16).cgPath
    }

    func update(with category: Category) {
        label.text = category.cellContent.title

        let baseColor = category.cellContent.backgroundColor
        gradientLayer.colors = baseColor.gradientColors

        layer.shadowColor = baseColor.cgColor
        layer.shadowOpacity = 0.35
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 8

        if let icon = category.cellContent.icon {
            let config = UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold)
            sfsymbolImage.image = UIImage(systemName: icon, withConfiguration: config)
        }
    }

    override func prepareForReuse() {
        label.text = nil
        sfsymbolImage.image = nil
        longPressAction = nil
    }

    @objc private func longPressGesture(gesture: UILongPressGestureRecognizer!) {
        guard gesture.state == .began else { return }
        longPressAction?()
    }
}
