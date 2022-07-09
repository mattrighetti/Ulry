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
    
    var onDoneAlertNotify: ((String, String) -> Void)? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Backup"
        
        dumpHelper.delegate = self
        
        cells = [
            [
                CellContent(
                    title: "Export database",
                    icon: "arrow.up.doc.fill",
                    isEnabled: true,
                    accessoryType: .accessoryType(.disclosureIndicator, .action({ [weak self] in
                        do {
                            let dbUrl = try FileManager.default
                                .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                                .appendingPathComponent("ulry.sqlite")
                            
                            let shareController = UIActivityViewController(activityItems: [dbUrl], applicationActivities: nil)
                            self?.present(shareController, animated: true)
                        } catch {
                            self?.onDoneAlertNotify?("Ops!", "Something went wrong while importing from file, try again later or report to developer. Error was \(error)")
                        }
                    }))
                ),
//                CellContent(
//                    title: "Import database",
//                    icon: "arrow.down.doc.fill",
//                    isEnabled: true,
//                    accessoryType: .accessoryType(.disclosureIndicator, .action({ [weak self] in
//                            guard let documentPicker = self?.documentPicker else { return }
//                            self?.navigationController?.present(documentPicker, animated: true)
//                        })
//                    )
//                )
            ]
        ]
    }
    
    private func popupCompletionViewContoller() {
        alertvc.message =  "Please wait..."

        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = UIActivityIndicatorView.Style.medium
        loadingIndicator.startAnimating();

        alertvc.view.addSubview(loadingIndicator)
        
        onDoneAlertNotify = { [weak self] title, message in
            loadingIndicator.stopAnimating()
            self?.alertvc.title = title
            self?.alertvc.message = message
            let okButton = UIAlertAction(title: "Ok", style: .cancel)
            self?.alertvc.addAction(okButton)
        }
        
        present(alertvc, animated: true, completion: nil)
    }
    
    private func initImport(for urls: [URL]) {
        if let url = urls.first {
            popupCompletionViewContoller()
            
            if FileManager.default.fileExists(atPath: url.path) {
                // TODO FileManager.default.copyItem(at: url, to: dburl)
                // TODO what if user wants to just import data of the database and not overwrite the existing one?
            } else {
                
            }
        }
    }
 }

extension BackupViewController: JSONDumpHelperDelegate {
    func helper(_: JSONDumpHelper, didFinishFetching links: [Link]) {
        DispatchQueue.main.async {
            self.onDoneAlertNotify?("Done", "Exported \(links.count) links")
        }
    }
    
    func helper(_: JSONDumpHelper, didFinishExporting links: [Link]) {
        DispatchQueue.main.async {
            self.onDoneAlertNotify?("Done!", "Exported all data to file")
        }
    }
}

extension BackupViewController: UIDocumentPickerDelegate {
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        // Runs when user selected a file
        self.initImport(for: urls)
    }
}
