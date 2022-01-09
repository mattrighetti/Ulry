//
//  UIColorCircleTableViewCell.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/8/22.
//

import UIKit
import SwiftUI

class UIColorCircleTableViewCell: UITableViewCell {
    var text: String? {
        didSet {
            label.text = text
        }
    }
    
    var count: Int? {
        didSet {
            guard let count = count else { return }
            countLabel.text = String(count)
        }
    }
    
    var color: UIColor? {
        didSet {
            coloredCircle.layer.backgroundColor = color?.cgColor
        }
    }
    
    lazy var coloredCircle: UIView = {
        let view = UIView()
        view.backgroundColor = color ?? .black
        view.layer.cornerRadius = 15
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var label: UILabel = {
        let label = UILabel()
        if let descriptor = UIFont.systemFont(ofSize: 14, weight: .semibold).fontDescriptor.withDesign(.rounded) {
            label.font = UIFont(descriptor: descriptor, size: 14)
        }
        label.text = text ?? ""
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var countLabel: UILabel = {
        let label = UILabel()
        if let descriptor = UIFont.systemFont(ofSize: 14, weight: .semibold).fontDescriptor.withDesign(.rounded) {
            label.font = UIFont(descriptor: descriptor, size: 14)
        }
        label.text = ""
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var imageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        separatorInset = UIEdgeInsets(top: 0, left: 50, bottom: 0, right: 0)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        contentView.addSubview(label)
        contentView.addSubview(countLabel)
        contentView.addSubview(coloredCircle)
        
        setupWithImage()
    }
    
    private func setupWithImage() {
        NSLayoutConstraint.activate([
            coloredCircle.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            coloredCircle.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            coloredCircle.widthAnchor.constraint(equalToConstant: 30),
            coloredCircle.heightAnchor.constraint(equalToConstant: 30),
            label.leadingAnchor.constraint(equalTo: coloredCircle.trailingAnchor, constant: 15),
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            countLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            countLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            countLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        coloredCircle.backgroundColor = nil
        label.text = nil
        countLabel.text = nil
    }
}
