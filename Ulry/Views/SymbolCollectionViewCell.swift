//
//  SymbolCollectionViewCell.swift
//  Ulry
//
//  Created by Mattia Righetti on 9/25/22.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import UIKit

class SymbolCollectionViewCell: UICollectionViewCell {
    var symbol: String? {
        didSet {
            symbolLabel.text = symbol
        }
    }
    
    var text: String? {
        didSet {
            textLablel.text = text
        }
    }
    
    var color: UIColor? {
        didSet {
            contentView.backgroundColor = color
        }
    }
    
    lazy var symbolLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var textLablel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(symbolLabel)
        addSubview(textLablel)
        
        NSLayoutConstraint.activate([
            symbolLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            symbolLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            symbolLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            
            textLablel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            textLablel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            textLablel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
