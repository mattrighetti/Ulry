//
//  AppearanceViewController.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/19/22.
//

import UIKit

class AppearanceViewController: UIStaticTableView {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Appearance"
        
        cells = [
            [
                CellContent(title: "Theme color", icon: "paintpalette", accessoryType: .accessoryType(.disclosureIndicator, .navigationController({
                    let alert = UIAlertController(title: "Select theme color", message: nil, preferredStyle: .actionSheet)
                    alert.addAction(UIAlertAction(title: "Light", style: .default, handler: { _ in
                        UserDefaults.standard.setValue(Theme.light.rawValue, forKey: Defaults.theme.rawValue)
                    }))
                    alert.addAction(UIAlertAction(title: "Dark", style: .default, handler: { _ in
                        UserDefaults.standard.setValue(Theme.dark.rawValue, forKey: Defaults.theme.rawValue)
                    }))
                    alert.addAction(UIAlertAction(title: "System", style: .default, handler: { _ in
                        UserDefaults.standard.setValue(Theme.system.rawValue, forKey: Defaults.theme.rawValue)
                    }))
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                    return alert
                })))
            ]
        ]
    }
}
