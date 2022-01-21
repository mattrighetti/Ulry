//
//  GeneralSettingsViewController.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/20/22.
//

import UIKit

class GeneralSettingsViewController: UIStaticTableView {
    init() {
        super.init(cells: [
            [
                CellContent(title: "Mark as read on open", icon: "checkmark", accessoryType: .viewInline({
                    let uiswitch = UISwitch()
                    uiswitch.isOn = UserDefaults.standard.value(forKey: Defaults.markReadOnOpen.rawValue) as! Bool
                    uiswitch.addAction(UIAction{ _ in
                        UserDefaults.standard.setValue(uiswitch.isOn, forKey: Defaults.markReadOnOpen.rawValue)
                    }, for: .valueChanged)
                    return uiswitch
                }))
            ],
            [
                CellContent(title: "Open links in-app", icon: "safari.fill", accessoryType: .viewInline({
                    let uiswitch = UISwitch()
                    uiswitch.isOn = UserDefaults.standard.value(forKey: Defaults.openInApp.rawValue) as! Bool
                    uiswitch.addAction(UIAction { _ in
                        UserDefaults.standard.setValue(uiswitch.isOn, forKey: Defaults.openInApp.rawValue)
                    }, for: .valueChanged)
                    return uiswitch
                })),
                CellContent(title: "Reader mode", icon: "quote.opening", accessoryType: .viewInline({
                    let uiswitch = UISwitch()
                    uiswitch.isOn = UserDefaults.standard.value(forKey: Defaults.readMode.rawValue) as! Bool
                    uiswitch.addAction(UIAction{ _ in
                        UserDefaults.standard.setValue(uiswitch.isOn, forKey: Defaults.readMode.rawValue)
                    }, for: .valueChanged)
                    return uiswitch
                }))
            ]
        ])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "General"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
