//
//  SpinnerViewController.swift
//  Ulry
//
//  Created by Mattia Righetti on 18/03/23.
//  Copyright © 2023 Mattia Righetti. All rights reserved.
//

import UIKit

class SpinnerViewController: UIViewController {
    private lazy var spinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        return spinner
    }()

    private lazy var label: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.textAlignment = .center
        label.lineBreakMode = .byWordWrapping
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override func loadView() {
        view = UIView()
        view.backgroundColor = UIColor(white: 0, alpha: 0.7)

        spinner.startAnimating()
        view.addSubview(spinner)
        view.addSubview(label)

        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.centerXAnchor.constraint(equalTo: spinner.centerXAnchor),
            label.topAnchor.constraint(equalTo: spinner.bottomAnchor, constant: 15),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 25),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -25)
        ])
    }

    func showText(texts: [String]) {
        let interval = 10.0
        var curr = 0.0

        for text in texts {
            DispatchQueue.main.asyncAfter(deadline: .now() + curr) {
                self.label.text = text
            }
            curr += interval
        }
    }
}
