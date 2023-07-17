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

    lazy var label: UILabel = {
        let label = UILabel()
        label.font = UIFont.rounded(ofSize: 15, weight: .regular)
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
        
        layer.cornerRadius = 15
        
        contentView.addSubview(label)
        contentView.addSubview(sfsymbolImage)

        let lpr = UILongPressGestureRecognizer(target: self, action: #selector(longPressGesture))
        lpr.minimumPressDuration = 0.5
        addGestureRecognizer(lpr)
        
        NSLayoutConstraint.activate([
            sfsymbolImage.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            sfsymbolImage.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            sfsymbolImage.widthAnchor.constraint(equalToConstant: 20),
            
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: sfsymbolImage.trailingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -5)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(with category: Category) {
        label.text = category.cellContent.title
        sfsymbolImage.tintColor = category.cellContent.backgroundColor
        
        backgroundColor = .lightGray.withAlphaComponent(0.2)
        
        if let icon = category.cellContent.icon {
            sfsymbolImage.image = UIImage(systemName: icon)
        }
    }
    
    override func prepareForReuse() {
        label.text = nil
        sfsymbolImage.image = nil
        longPressAction = nil
    }

    @objc private func longPressGesture(gesture : UILongPressGestureRecognizer!) {
        guard gesture.state == .began else { return }
        longPressAction?()
    }
}
