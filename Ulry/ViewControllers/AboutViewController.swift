//
//  AboutViewController.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/19/22.
//

import UIKit

class AboutViewController: UIStaticTableView {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "About"
        
        let contact = CellContent(title: "Contact", icon: "envelope.fill", accessoryType: .accessoryType(.disclosureIndicator, .action({
            UIApplication.shared.open(URL(string: "mailto:matt95.righetti+ulry@gmail.com")!)
        })))
        
        let website = CellContent(title: "Developer Website", icon: "network", accessoryType: .accessoryType(.disclosureIndicator, .action({
            UIApplication.shared.open(URL(string: "https://mattrighetti.github.io")!)
        })))
        
        let privacyPolicy = CellContent(title: "Privacy Policy", icon: "hand.raised.fill", isEnabled: false, accessoryType: .accessoryType(.disclosureIndicator, .navigationController({
            let alert = UIAlertController(title: "⚠️ Not ready yet", message: "This will eventually be available in a production release", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            return alert
        })))
        
        cells = [[contact, website], [privacyPolicy]]
    }
}
