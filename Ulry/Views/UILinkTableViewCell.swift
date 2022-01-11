//
//  UILinkTableViewCell.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/9/22.
//

import UIKit
import SwiftUI

class UILinkTableViewCell: UITableViewCell {
    var link: Link? {
        didSet {
            guard let link = link else { return }
            setupCellWithLink(link: link)
        }
    }
    
    var action: (() -> Void)?
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.font = UIFont.rounded(ofSize: 17, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.textColor = .systemGray
        label.numberOfLines = 2
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.rounded(ofSize: 11, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var image: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 10
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(onInfoButtonPressed)))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    lazy var backgroundLabelImage: UIView = {
        let backgroundView = UIView()
        backgroundView.backgroundColor = .red
        backgroundView.layer.cornerRadius = 10
        backgroundView.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(onInfoButtonPressed)))
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        return backgroundView
    }()
    
    lazy var hostLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.rounded(ofSize: 23, weight: .black)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var urlHostnameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.monospacedSystemFont(ofSize: 10, weight: .regular)
        label.textColor = .systemBlue
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        contentView.addSubview(backgroundLabelImage)
        contentView.addSubview(urlHostnameLabel)
        contentView.addSubview(hostLabel)
        contentView.addSubview(dateLabel)
        contentView.addSubview(titleLabel)
        contentView.addSubview(image)
        contentView.addSubview(descriptionLabel)
        
        NSLayoutConstraint.activate([
            backgroundLabelImage.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            backgroundLabelImage.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            backgroundLabelImage.widthAnchor.constraint(equalToConstant: 60),
            backgroundLabelImage.heightAnchor.constraint(equalToConstant: 60),
            
            image.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            image.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            image.widthAnchor.constraint(equalToConstant: 60),
            image.heightAnchor.constraint(equalToConstant: 60),
            
            hostLabel.centerYAnchor.constraint(equalTo: backgroundLabelImage.centerYAnchor),
            hostLabel.centerXAnchor.constraint(equalTo: backgroundLabelImage.centerXAnchor),
            
            urlHostnameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            urlHostnameLabel.leadingAnchor.constraint(equalTo: backgroundLabelImage.trailingAnchor, constant: 10),
            urlHostnameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            
            titleLabel.topAnchor.constraint(equalTo: urlHostnameLabel.bottomAnchor, constant: 3),
            titleLabel.leadingAnchor.constraint(equalTo: backgroundLabelImage.trailingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            
            descriptionLabel.topAnchor.constraint(greaterThanOrEqualTo: titleLabel.bottomAnchor, constant: 3),
            descriptionLabel.leadingAnchor.constraint(equalTo: backgroundLabelImage.trailingAnchor, constant: 10),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            descriptionLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            
            dateLabel.topAnchor.constraint(greaterThanOrEqualTo: backgroundLabelImage.bottomAnchor, constant: 5),
            dateLabel.centerXAnchor.constraint(equalTo: backgroundLabelImage.centerXAnchor),
            dateLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCellWithLink(link: Link) {
        urlHostnameLabel.text = link.hostname
        hostLabel.text = link.hostname.first!.uppercased()
        dateLabel.text = link.dateString
        backgroundLabelImage.backgroundColor = UIColor(hex: link.colorHex)
        
        if let data = link.imageData {
            if let img = UIImage(data: data) {
                image.image = img
                backgroundLabelImage.isHidden = true
            } else {
                image.isHidden = true
            }
        } else {
            image.isHidden = true
        }
        
        if let title = link.ogTitle {
            titleLabel.text = title
        } else {
            titleLabel.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
            titleLabel.text = link.url
        }
        
        if let description = link.ogDescription {
            descriptionLabel.text = description
        } else {
            descriptionLabel.isHidden = true
        }
    }
    
    override func prepareForReuse() {
        image.isHidden = false
        image.image = nil
        hostLabel.text = nil
        dateLabel.text = nil
        urlHostnameLabel.text = nil
        descriptionLabel.text = nil
        titleLabel.text = nil
        backgroundLabelImage.isHidden = false
    }
    
    @objc private func onInfoButtonPressed() {
        action?()
    }
}
