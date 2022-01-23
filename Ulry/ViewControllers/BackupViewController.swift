//
//  BackupViewController.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/22/22.
//

import UIKit
import MobileCoreServices

class BackupViewController: UIStaticTableView {
    var dumpHelper = JSONDumpHelper()
    
    lazy var documentPicker: UIDocumentPickerViewController = {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.json], asCopy: false)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        return documentPicker
    }()
    
    var alertvc: UIAlertController = {
        let uialert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        return uialert
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Backup"
        
        dumpHelper.delegate = self
        
        cells = [
            [
                CellContent(
                    title: "Export to file",
                    icon: "arrow.up.doc.fill",
                    isEnabled: false,
                    accessoryType: .accessoryType(.disclosureIndicator, .action({ [weak self] in
                        do {
                            self?.alertvc.title = "Exporting"
                            self?.alertvc.message = "Exporting data to file..."
                            self?.alertvc.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                            self?.alertvc.actions.first?.isEnabled = false
                            guard let alertvc = self?.alertvc else { return }
                            self?.navigationController?.present(alertvc, animated: false, completion: nil)
                            
                            try self?.dumpHelper.dumpAllToDocumentFile()
                            
                            self?.alertvc.title = "Done"
                            self?.alertvc.message = "Exported data correctly"
                            self?.alertvc.actions.first?.isEnabled = true
                        } catch {
                            self?.alertvc.title = "Ops!"
                            self?.alertvc.message = "Something went wrong while importing from file, try again later or report to developer"
                            self?.alertvc.actions.first?.isEnabled = true
                        }
                    }))
                ),
                CellContent(
                    title: "Load from file",
                    icon: "arrow.down.doc.fill",
                    isEnabled: false,
                    accessoryType: .accessoryType(
                        .disclosureIndicator,
                        .action({ [weak self] in
                            guard let documentPicker = self?.documentPicker else { return }
                            self?.navigationController?.present(documentPicker, animated: true)
                        })
                    )
                )
            ],
            [
                CellContent(
                    title: "iCloud sync",
                    subtitle: "Premium members only",
                    icon: "arrow.clockwise.icloud.fill",
                    isEnabled: false,
                    accessoryType: .viewInline({
                        let uiswitch = UISwitch()
                        uiswitch.isEnabled = false
                        // TODO save to user defaults
                        return uiswitch
                    })
                )
            ]
        ]
    }
 }

extension BackupViewController: JSONDumpHelperDelegate {
    func helper(_: JSONDumpHelper, didFinishFetching: [Link]) {
        self.alertvc.title = "Done"
        self.alertvc.message = "Loaded \(didFinishFetching.count) correclty!"
        self.alertvc.actions.first?.isEnabled = true
    }
}

extension BackupViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let url = urls.first {
            self.alertvc.title = "Importing"
            self.alertvc.message = "Fetching data..."
            self.alertvc.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            self.alertvc.actions.first?.isEnabled = false
            self.navigationController?.present(self.alertvc, animated: false, completion: nil)
            
            DispatchQueue(label: "com.mattrighetti.Ulry.LoadFromFile").async {
                do {
                    try self.dumpHelper.loadFromFile(from: url)
                } catch {
                    self.alertvc.title = "Ops!"
                    self.alertvc.message = "Something went wrong while importing from file, try again later or report to developer"
                    self.alertvc.actions.first?.isEnabled = true
                }
            }
        }
    }
}
