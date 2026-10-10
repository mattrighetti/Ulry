//
//  BouncyCollectionViewCell.swift
//  Ulry
//
//  Created by Mattia Righetti on 16/04/23.
//  Copyright © 2023 Mattia Righetti. All rights reserved.
//

import UIKit

class BouncyCollectionViewCell: UICollectionViewCell {
    private func setPressed(_ isPressed: Bool) {
        guard !UIAccessibility.isReduceMotionEnabled else {
            transform = .identity
            return
        }
        UIView.animate(
            withDuration: 0.18,
            delay: 0,
            usingSpringWithDamping: 0.82,
            initialSpringVelocity: 0,
            options: [.allowUserInteraction, .beginFromCurrentState]
        ) {
            self.transform = isPressed ? CGAffineTransform(scaleX: 0.975, y: 0.975) : .identity
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        setPressed(true)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        setPressed(false)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        setPressed(false)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        layer.removeAllAnimations()
        transform = .identity
    }
}
