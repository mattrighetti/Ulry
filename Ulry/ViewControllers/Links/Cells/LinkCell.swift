//
//  UILinkTableViewCell.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/9/22.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import UIKit
import Links

fileprivate let imageSize: CGFloat = {
    if UIDevice.current.userInterfaceIdiom == .pad {
        return 80.0
    } else {
        return 60.0
    }
}()

class LinkCell: UITableViewCell {
    public static let reuseIdentifier = "LinkCell"

    private let titleFont = UIFont.preferredFont(for: .callout, weight: .semibold)
    private let descriptionFont = UIFont.preferredFont(forTextStyle: .caption1)
    private let titleMonospaceFont = UIFont.monospacedSystemFont(ofSize: 13, weight: .regular)
    
    private enum Appearence: String, Hashable, Equatable {
        case complete
        case standard
        case minimal
    }
    
    private var appearence: Appearence {
        get {
            Appearence(rawValue: UserDefaultsWrapper().get(key: .linkCellAppearence))!
        }
    }
    
    var link: Link? {
        didSet {
            guard let link = link else { return }
            setupCellWithLink(link: link)
        }
    }
    
    var action: (() -> Void)? {
        didSet {
            linkImagePreview.action = action
        }
    }
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.font = titleFont
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.textColor = .systemGray
        label.numberOfLines = 2
        label.font = descriptionFont
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var linkImagePreview: LinkImagePreview = {
        let linkImagePreview = LinkImagePreview()
        linkImagePreview.translatesAutoresizingMaskIntoConstraints = false
        return linkImagePreview
    }()
    
    lazy var urlHostnameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.monospacedSystemFont(ofSize: 10, weight: .semibold)
        label.textColor = .systemBlue
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var tagsDetailLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(for: .caption2, weight: .bold)
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var verticalStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fillProportionally
        stackView.alignment = .leading
        stackView.spacing = 3
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    lazy var sideImageView: UIImageView = {
        let view = UIImageView()
        return view
    }()
    
    lazy var horizontalStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.distribution = .fill
        stackView.alignment = .top
        stackView.spacing = 10
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        backgroundColor = UIColor(named: "bg-color")
        setupContraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupContraints() {
        verticalStackView.addArrangedSubview(urlHostnameLabel)
        verticalStackView.addArrangedSubview(titleLabel)
        verticalStackView.addArrangedSubview(descriptionLabel)
        verticalStackView.addArrangedSubview(tagsDetailLabel)
        
        horizontalStackView.addArrangedSubview(sideImageView)
        horizontalStackView.addArrangedSubview(linkImagePreview)
        horizontalStackView.addArrangedSubview(verticalStackView)
        
        let widthLs = sideImageView.widthAnchor.constraint(equalToConstant: 12)
        let widthImageConstraint = linkImagePreview.widthAnchor.constraint(equalToConstant: imageSize)
        let heightImageConstraint = linkImagePreview.heightAnchor.constraint(equalToConstant: imageSize)
        
        for constraint in [widthLs, widthImageConstraint, heightImageConstraint] {
            constraint.priority = .init(999)
            constraint.isActive = true
        }
        
        contentView.addSubview(horizontalStackView)

        NSLayoutConstraint.activate([
            horizontalStackView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            horizontalStackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            horizontalStackView.widthAnchor.constraint(equalTo: contentView.widthAnchor),
            horizontalStackView.heightAnchor.constraint(equalTo: contentView.heightAnchor)
        ])
    }
    
    private func setupAppearence(_ appearence: Appearence) {
        switch appearence {
        case .minimal:
            linkImagePreview.isHidden = true
            descriptionLabel.isHidden = true
        case .standard:
            linkImagePreview.isHidden = true
        default: break
        }
    }
    
    // Sets min height to cell
    override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
        if appearence == .complete {
            let size = super.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: horizontalFittingPriority, verticalFittingPriority: verticalFittingPriority)
            let minHeight = imageSize + 20.0
            return CGSize(width: size.width, height: max(size.height, minHeight))
        }
        
        return super.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: horizontalFittingPriority, verticalFittingPriority: verticalFittingPriority)
    }
    
    private func setupCellWithLink(link: Link) {
        urlHostnameLabel.text = link.hostname
        
        setupAppearence(appearence)
        setupSideLabel()
        setupImageData()
        setupTitleLabel()
        setupDescriptionLabel()
        setupTagsLabel()
    }
    
    private func setupSideLabel() {
        let largeFont = UIFont.systemFont(ofSize: 10)
        let configuration = UIImage.SymbolConfiguration(font: largeFont)
        
        if link!.starred {
            sideImageView.image = UIImage(systemName: "star.circle.fill", withConfiguration: configuration)!
            sideImageView.tintColor = .systemYellow
        } else if link!.unread {
            sideImageView.image = UIImage(systemName: "circle.fill", withConfiguration: configuration)
            sideImageView.tintColor = .systemBlue
        } else {
            sideImageView.tintColor = .clear
        }
    }
    
    private func setupImageData() {
        if let img = ImageStorage.shared.getImage(for: link!) {
            linkImagePreview.image.image = img
            linkImagePreview.image.backgroundColor = nil
            linkImagePreview.urlLetterLabel.text = nil
        } else {
            linkImagePreview.image.image = nil
            linkImagePreview.image.backgroundColor = UIColor(hex: link!.colorHex)!
            linkImagePreview.urlLetterLabel.text = link!.hostname.first!.uppercased()
        }
    }
    
    private func setupTitleLabel () {
        if let title = link!.ogTitle {
            titleLabel.font = titleFont
            titleLabel.text = title
        } else {
            titleLabel.font = titleMonospaceFont
            titleLabel.text = link!.url
        }
    }
    
    private func setupDescriptionLabel() {
        if let description = link!.ogDescription {
            descriptionLabel.text = description
        } else {
            descriptionLabel.isHidden = true
        }
    }
    
    private func setupTagsLabel() {
        if let tags = link!.tags {
            tagsDetailLabel.isHidden = false
            tagsDetailLabel.attributedText = NSMutableAttributedString(
                coloredStrings: tags.map { ($0.name, UIColor(hex: $0.colorHex)!) },
                separator: " · "
            )
        } else {
            tagsDetailLabel.isHidden = true
        }
    }
    
    override func prepareForReuse() {
        urlHostnameLabel.text = nil
        descriptionLabel.text = nil
        titleLabel.text = nil
        tagsDetailLabel.text = nil
        descriptionLabel.isHidden = false
    }
}
