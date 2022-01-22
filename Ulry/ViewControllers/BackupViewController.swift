//
//  BackupViewController.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/22/22.
//

import UIKit
import MobileCoreServices

class BackupViewController: UIStaticTableView {
    lazy var documentPicker: UIDocumentPickerViewController = {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.json], asCopy: false)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        return documentPicker
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Backup"
        
        cells = [[
            CellContent(
                title: "Export to file",
                icon: "arrow.up.doc.fill",
                accessoryType: .accessoryType(.disclosureIndicator, .action({
                    JSONDumpHelper.dumpAllToDocumentFile()
                }))
            ),
            CellContent(
                title: "Load from file",
                icon: "arrow.down.doc.fill",
                accessoryType: .accessoryType(.disclosureIndicator, .action({ [weak self] in
                    guard let documentPicker = self?.documentPicker else { return }
                    self?.navController?.present(documentPicker, animated: true)
                }))
            )
        ]]
    }
}

extension BackupViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let url = urls.first {
            JSONDumpHelper.loadFromFile(from: url)
        }
    }
}
