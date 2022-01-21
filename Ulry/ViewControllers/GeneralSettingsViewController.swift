//
//  GeneralSettingsViewController.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/20/22.
//

import UIKit

enum CellType: Hashable {
    case basic(title: String, subtitle: String?, iconName: String?)
    case custom(title: String, subtitle: String?, iconName: String?, accessoryView: UIView?)
}

struct CellContent: Hashable, Equatable {
    var title: String
    var subtitle: String? = nil
    var icon: String? = nil
    var accessoryView: (() -> UIView)? = nil
    
    var id: UUID = UUID()
    
    static func == (lhs: CellContent, rhs: CellContent) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

class GeneralSettingsViewController: UIViewController {
    let cells: [CellContent] = {
        return [
            CellContent(title: "Mark as read on open", accessoryView: {
                let uiswitch = UISwitch()
                uiswitch.isOn = UserDefaults.standard.value(forKey: Defaults.markReadOnOpen.rawValue) as! Bool
                uiswitch.addAction(UIAction{ _ in
                    UserDefaults.standard.setValue(uiswitch.isOn, forKey: Defaults.markReadOnOpen.rawValue)
                }, for: .valueChanged)
                return uiswitch
            }),
            CellContent(title: "Open links in-app", accessoryView: {
                let uiswitch = UISwitch()
                uiswitch.isOn = UserDefaults.standard.value(forKey: Defaults.openInApp.rawValue) as! Bool
                uiswitch.addAction(UIAction { _ in
                    UserDefaults.standard.setValue(uiswitch.isOn, forKey: Defaults.openInApp.rawValue)
                }, for: .valueChanged)
                return uiswitch
            }),
            CellContent(title: "Reader mode", accessoryView: {
                let uiswitch = UISwitch()
                uiswitch.isOn = UserDefaults.standard.value(forKey: Defaults.readMode.rawValue) as! Bool
                uiswitch.addAction(UIAction{ _ in
                    UserDefaults.standard.setValue(uiswitch.isOn, forKey: Defaults.readMode.rawValue)
                }, for: .valueChanged)
                return uiswitch
            })
        ]
    }()
    
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        return tableView
    }()
    
    lazy var datasource: UITableViewDiffableDataSource<Int, CellContent> = {
        let datasource = UITableViewDiffableDataSource<Int, CellContent>(tableView: tableView) { tableView, indexPath, cellContent in
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            var cellConfig = UIListContentConfiguration.subtitleCell()
            
            cellConfig.text = cellContent.title
            cellConfig.textProperties.font = UIFont.rounded(ofSize: 14, weight: .semibold)
            
            cellConfig.secondaryText = cellContent.subtitle
            cellConfig.secondaryTextProperties.font = UIFont.rounded(ofSize: 11, weight: .regular)
            cellConfig.textToSecondaryTextVerticalPadding = 5.0
            
            if let icon = cellContent.icon, let image = UIImage(systemName: icon) {
                cellConfig.image = image
            }
            
            cell.accessoryView = cellContent.accessoryView?()
            cell.contentConfiguration = cellConfig
            
            return cell
        }
        
        return datasource
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(tableView)
        
        setupCells()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
    
    func setupCells() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, CellContent>()
        
        snapshot.appendSections([0])
        snapshot.appendItems(cells, toSection: 0)
        
        datasource.apply(snapshot, animatingDifferences: false)
    }
}
