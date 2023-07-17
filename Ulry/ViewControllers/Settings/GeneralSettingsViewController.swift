//
//  GeneralSettingsVC.swift
//  Ulry
//
//  Created by Mattia Righetti on 10/25/22.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import UIKit

class GeneralSettingsViewController: GenericCollectionList {
    
    private lazy var markAsReadOnOpenButton: CollectionViewCellContent = {
        let uiswitch = UISwitch()
        uiswitch.isOn = UserDefaultsWrapper().get(key: .markReadOnOpen)
        
        let action = UIAction { _ in
            UserDefaultsWrapper().set(uiswitch.isOn, forKey: .markReadOnOpen)
        }
        
        uiswitch.addAction(action, for: .valueChanged)
        
        let customSwitchView = UICellAccessory.CustomViewConfiguration(customView: uiswitch, placement: .trailing())
        return .setting(CVSetting(image: "checkmark", text: "Read on open", secondaryText: "Automatically set as read link when opened", accessories: [.customView(configuration: customSwitchView)], hexColor: "D8335B"))
    }()
    
    private lazy var openLinksInAppButton: CollectionViewCellContent = {
        let uiswitch = UISwitch()
        
        uiswitch.isOn = UserDefaultsWrapper().get(key: .openInApp)
        
        let action = UIAction { _ in
            UserDefaultsWrapper().set(uiswitch.isOn, forKey: .openInApp)
        }
        
        uiswitch.addAction(action, for: .valueChanged)
        
        let customSwitchView = UICellAccessory.CustomViewConfiguration(customView: uiswitch, placement: .trailing())
        return .setting(CVSetting(image: "safari.fill", text: "Open links in-app", secondaryText: "Open links in browser without leaving the app", accessories: [.customView(configuration: customSwitchView)], hexColor: "FF6766"))
    }()
    
    private lazy var readerMode: CollectionViewCellContent = {
        let uiswitch = UISwitch()
        
        uiswitch.isOn = UserDefaultsWrapper().get(key: .readMode)
        
        let action = UIAction { _ in
            UserDefaultsWrapper().set(uiswitch.isOn, forKey: .readMode)
        }
        
        uiswitch.addAction(action, for: .valueChanged)
        
        let customSwitchView = UICellAccessory.CustomViewConfiguration(customView: uiswitch, placement: .trailing())
        return .setting(CVSetting(image: "quote.opening", text: "Reader mode", secondaryText: "If website is compatible, automatically activate Reader Mode when opening link", accessories: [.customView(configuration: customSwitchView)], hexColor: "3D8EB9"))
    }()
    
    private lazy var urlRedirectorSettings: CollectionViewCellContent = {
        var cvsetting = CVSetting(
            image: "arrow.triangle.branch",
            text: "Privacy Redirector",
            secondaryText: "Redirect social media platforms and paywalled websites to their privacy respecting and free alternatives",
            accessories: [.disclosureIndicator()],
            hexColor: "EF9688",
            isSelectable: true
        )
        
        return .navigate(cvsetting, URLRedirectorSettings())
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "General"
        
        content = [
            [markAsReadOnOpenButton],
            [openLinksInAppButton, readerMode],
            [urlRedirectorSettings]
        ]
        
        super.setup()
    }
    
}


