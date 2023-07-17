//
//  TagCategoryCollectionViewCell.swift
//  Ulry
//
//  Created by Mattia Righetti on 10/10/22.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import UIKit

class TagCollectionViewCell: BouncyCollectionViewCell {

    var longPressAction: (() -> Void)? = nil
    
    lazy var label: UILabel = {
        let label = UILabel()
        label.font = UIFont.rounded(ofSize: 15, weight: .regular)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        let lpr = UILongPressGestureRecognizer(target: self, action: #selector(longPressGesture))
        lpr.minimumPressDuration = 0.5
        addGestureRecognizer(lpr)
        
        layer.borderColor = UIColor.white.withAlphaComponent(0.1).cgColor
        layer.borderWidth = 1
        layer.cornerRadius = 15
        
        contentView.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(with category: Category) {
        backgroundColor = category.cellContent.backgroundColor
        label.text = category.cellContent.title
    }
    
    override func prepareForReuse() {
        label.text = nil
        longPressAction = nil
    }

    @objc private func longPressGesture(gesture : UILongPressGestureRecognizer!) {
        guard gesture.state == .began else { return }
        longPressAction?()
    }
}
