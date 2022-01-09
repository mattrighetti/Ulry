//
//  UIImageCircleTableViewCell.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/8/22.
//

import UIKit
import SwiftUI

class UIImageCircleTableViewCell: UIColorCircleTableViewCell {
    var icon: String? {
        didSet {
            imgView.image = UIImage(systemName: icon!)
        }
    }
    
    lazy var imgView: UIImageView = {
        let symbol = UIImage(systemName: icon ?? "trash")
        let imgview = UIImageView(image: UIImage(systemName: icon ?? "trash"))
        imgview.layer.cornerRadius = 10
        imgview.layer.backgroundColor = UIColor.clear.cgColor
        imgview.tintColor = .white
        imgview.translatesAutoresizingMaskIntoConstraints = false
        return imgview
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        separatorInset = UIEdgeInsets(top: 0, left: 50, bottom: 0, right: 0)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.addSubview(imgView)
        
        setupWithImage()
    }
    
    private func setupWithImage() {
        NSLayoutConstraint.activate([
            imgView.centerXAnchor.constraint(equalTo: coloredCircle.centerXAnchor),
            imgView.centerYAnchor.constraint(equalTo: coloredCircle.centerYAnchor),
            imgView.widthAnchor.constraint(equalToConstant: 17),
            imgView.heightAnchor.constraint(equalToConstant: 17)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        imgView.image = nil
    }
}
