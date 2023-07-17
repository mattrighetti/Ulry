//
//  CollectionViewHeader.swift
//  Ulry
//
//  Created by Mattia Righetti on 9/25/22.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import UIKit

protocol HomeHeaderCollectionViewCellDelegate: NSObject {
    func toggle(section: HomeCollectionViewSection)
}

class HomeHeaderCollectionViewCell: UICollectionViewListCell {
    weak var delegate: HomeHeaderCollectionViewCellDelegate?
    var section: HomeCollectionViewSection!
    var isExpanded: Bool = false {
        didSet {
            UIView.animate(withDuration: 0.2) {
                self.arrow.transform = CGAffineTransformMakeRotation(!self.isExpanded ? Double.pi / 2 : 0)
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        didTap()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        let customView = UICellAccessory.CustomViewConfiguration(customView: arrow, placement: .trailing(), reservedLayoutWidth: .custom(40), maintainsFixedSize: false)
        self.accessories = [.customView(configuration: customView)]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func didTap() {
        delegate?.toggle(section: section)
        isExpanded.toggle()
    }

    private lazy var arrow: UILabel = {
        let label = UILabel()
        let attachment = NSTextAttachment()
        let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: 17, weight: .regular, scale: .medium)
        attachment.image = UIImage(systemName: "chevron.forward.circle", withConfiguration: symbolConfiguration)?.withTintColor(.systemBlue)
        label.attributedText = NSMutableAttributedString(attachment: attachment)
        return label
    }()
}
