//
//  EmptinessView.swift
//  Ulry
//
//  Created by Mattia Righetti on 10/16/22.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import UIKit
import Lottie

class EmptinessView: UIView {
    
    lazy var vstack: UIStackView = {
        let vstack = UIStackView()
        vstack.axis = .vertical
        vstack.spacing = 10
        vstack.alignment = .center
        vstack.distribution = .fillProportionally
        vstack.translatesAutoresizingMaskIntoConstraints = false
        return vstack
    }()
    
    lazy var animationView: LottieAnimationView = {
        let view = LottieAnimationView(asset: "astronaut")
        view.contentMode = .scaleAspectFit
        view.loopMode = .loop
        view.animationSpeed = 1
        return view
    }()
    
    lazy var emptinessLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(for: .title3, weight: .bold)
        label.text = "Nothing to see here"
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(vstack)
        
        vstack.addArrangedSubview(animationView)
        vstack.addArrangedSubview(emptinessLabel)
        
        let hc = animationView.heightAnchor.constraint(equalToConstant: 300)
        hc.priority = .init(999)
        hc.isActive = true
        
        let wc = animationView.widthAnchor.constraint(equalToConstant: 300)
        wc.priority = .init(999)
        wc.isActive = true
        
        let lc = emptinessLabel.heightAnchor.constraint(equalToConstant: 40)
        lc.priority = .init(999)
        lc.isActive = true
        
        NSLayoutConstraint.activate([
            vstack.centerYAnchor.constraint(equalTo: centerYAnchor),
            vstack.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
        
        animationView.play()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
