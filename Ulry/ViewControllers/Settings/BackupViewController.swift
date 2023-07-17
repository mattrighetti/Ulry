//
//  BackupCollectionViewController.swift
//  Ulry
//
//  Created by Mattia Righetti on 10/26/22.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import os
import UIKit
import Account
import UniformTypeIdentifiers

private enum Setting: Hashable {
    case exportDatabase
    case exportData
    case importData
    
    var icon: String {
        switch self {
        case .exportDatabase: return "cylinder.split.1x2"
        case .exportData: return "arrow.up.doc.fill"
        case .importData: return "arrow.down.doc.fill"
        }
    }
    
    var title: String {
        switch self {
        case .exportDatabase: return "Export database"
        case .exportData: return "Export data"
        case .importData: return "Import data"
        }
    }

    var subtext: String? {
        switch self {
        case .exportData:
            return "Exports app's data to a file that can later be imported on another device"
        default:
            return nil
        }
    }
    
    var hexColor: String {
        switch self {
        case .exportDatabase: return "4d6760"
        case .exportData: return "44aadd"
        case .importData: return "820eb3"
        }
    }
}

class BackupViewController: UIViewController {

    var account: Account!
    
    private lazy var collectionview: UICollectionView = {
        var config = UICollectionLayoutListConfiguration.withCustomBackground(appearance: .insetGrouped)
        
        let layout = UICollectionViewCompositionalLayout.list(using: config)
        
        let collectionview = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionview.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        collectionview.translatesAutoresizingMaskIntoConstraints = false
        return collectionview
    }()
    
    private lazy var datasource: UICollectionViewDiffableDataSource<Int, Setting> = {
        // MARK: - Cell Configuration
        
        let settingsCellConfiguration = UICollectionView.CellRegistration<UICollectionViewCellCustomBackground, Setting> { cell, indexPath, content in
            var configuration = cell.defaultContentConfiguration()
            
            configuration.text = content.title
            configuration.secondaryText = content.subtext
            configuration.secondaryTextProperties.color = .secondaryLabel
            configuration.imageToTextPadding = 10
            configuration.imageProperties.tintColor = .white
            configuration.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 15, leading: 15, bottom: 15, trailing: 0)
            
            cell.contentConfiguration = configuration
            
            let customImage = UICellAccessory.CustomViewConfiguration(
                customView: BackgroundImage.getHostingViewController(icon: content.icon, hex: content.hexColor),
                placement: .leading()
            )

            cell.accessories = [.disclosureIndicator(), .customView(configuration: customImage)]
        }
        
        // MARK: - DataSource
        let datasource = UICollectionViewDiffableDataSource<Int, Setting>(collectionView: collectionview) { collectionView, indexPath, s in
            return collectionView.dequeueConfiguredReusableCell(using: settingsCellConfiguration, for: indexPath, item: s)
        }
        
        return datasource
    }()

    private lazy var spinner = {
        return SpinnerViewController()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Backup"
        
        collectionview.delegate = self
        view.addSubview(collectionview)
        
        setup()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionview.frame = view.bounds
    }
    
    private func setup() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, Setting>()
        snapshot.appendSections([0,1])
        snapshot.appendItems([.exportDatabase, .exportData], toSection: 0)
        snapshot.appendItems([.importData], toSection: 1)
        datasource.apply(snapshot, animatingDifferences: false)
    }

    private func showCompletion(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        present(alert, animated: true)
    }

    private func showExportDatabase(sourceRect: CGRect) {
        let dbUrl = Paths.dataFolder.appendingPathComponent("ulry.sqlite")

        let activity: UIActivityViewController = {
            let activity = UIActivityViewController.share(file: dbUrl, title: "Ulry database")
            activity.completionWithItemsHandler = { [unowned self] (type, complete, _, _) in
                if complete {
                    self.showCompletion(title: "Exported", message: "Ulry's database has been exported correctly")
                }
            }
            activity.popoverPresentationController?.sourceView = collectionview
            activity.popoverPresentationController?.sourceRect = sourceRect
            return activity
        }()

        present(activity, animated: true)
    }

    private func showExportLinks(sourceRect: CGRect) {
        guard let data = try? account.exportToBinary() else {
            fatalError("could not export links to binary file")
        }

        do {
            let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("backup").appendingPathExtension("json")
            try data.write(to: fileURL)

            let activity: UIActivityViewController = {
                let activity = UIActivityViewController.share(file: fileURL, title: "Ulry links")
                activity.completionWithItemsHandler = { [unowned self] (type, complete, _, _) in
                    if complete {
                        self.showCompletion(title: "Exported", message: "Ulry's database has been exported correctly")
                    }
                }
                activity.popoverPresentationController?.sourceView = collectionview
                activity.popoverPresentationController?.sourceRect = sourceRect
                return activity
            }()

            present(activity, animated: true)
        } catch {
            fatalError()
        }
    }

    private func selectImportFile(sourceRect: CGRect) {
        let alert = UIAlertController(title: "Import Links", message: "Ulry will import links, groups and tags without caring about duplicates. Do you want to proceed?", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Proceed", style: .default) { [unowned self] action in
            let types = UTType.types(tag: "json", tagClass: UTTagClass.filenameExtension, conformingTo: nil)
            let documentPickerController = UIDocumentPickerViewController(forOpeningContentTypes: types)
            documentPickerController.delegate = self
            self.present(documentPickerController, animated: true, completion: nil)
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(okAction)
        alert.addAction(cancelAction)

        present(alert, animated: true)
    }

    private func showImportCompletion(numLinks: Int, numGroups: Int, numTags: Int) {
        if numLinks == 0 && numGroups == 0 && numTags == 0 {
            showCompletion(title: "Success", message: "Everything is up to date!")
        } else {
            showCompletion(title: "Success", message: "\(numLinks) links, \(numGroups) groups and \(numTags) tags were imported with success.")
        }
    }
}

extension BackupViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let setting = datasource.itemIdentifier(for: indexPath) else { return }
        guard let cell = collectionView.cellForItem(at: indexPath) else { return }
        let rect = cell.convert(cell.contentView.frame, to: collectionview)

        if case .exportDatabase = setting {
            showExportDatabase(sourceRect: rect)
        } else if case .exportData = setting {
            showExportLinks(sourceRect: rect)
        } else if case .importData = setting {
            selectImportFile(sourceRect: rect)
        }
        
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}

extension BackupViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        Task {
            spinner.add(self, frame: view.frame)
            spinner.showText(texts: [
                "Syncing links, please don't close the app..",
                "Images can take a while to download, please don't close the app..",
            ])

            do {
                switch try await account.importFromBinary(urls.first!) {
                case .success(let importedDataCount):
                    showImportCompletion(numLinks: importedDataCount.links, numGroups: importedDataCount.groups, numTags: importedDataCount.tags)
                case .failure(let error):
                    self.showCompletion(title: error.title, message: error.message)
                }
                spinner.remove()
            } catch {
                self.showCompletion(title: "Error", message: "There was an error importing data from file, make sure that you selected a compatible file and that it is not corrupted and try again.")
            }
        }
    }
}
