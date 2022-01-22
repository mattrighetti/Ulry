//
//  UIStaticTableView.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/21/22.
//

import UIKit

struct CellContent: Hashable, Equatable {
    enum AccessoryType {
        case view(UIView)
        case viewInline((() -> UIView))
        case accessoryType(UITableViewCell.AccessoryType, ActionType?)
        
        enum ActionType {
            case navigationController((() -> UIViewController))
            case action((() -> Void))
        }
    }
    
    
    
    var title: String
    var subtitle: String? = nil
    var icon: String? = nil
    var accessoryType: AccessoryType? = nil
    
    var id: UUID = UUID()
    
    static func == (lhs: CellContent, rhs: CellContent) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

class UIStaticTableView: UIViewController {
    var cells: [[CellContent]]? {
        didSet {
            setupCells()
        }
    }
    
    var navController: UINavigationController? {
        get {
            self.navigationController
        }
    }
    
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
                cellConfig.imageProperties.tintColor = .label
            }
            
            switch cellContent.accessoryType {
            case .view(let view):
                cell.accessoryView = view
            case .viewInline(let view):
                cell.accessoryView = view()
            case .accessoryType(let type, let action):
                cell.accessoryType = type
            case .none:
                break
            }
            
            cell.contentConfiguration = cellConfig
            return cell
        }
        
        return datasource
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        view.addSubview(tableView)
        
        setupCells()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Fade the table deselection as the view controller is popped
        if let selectedIndexPath = tableView.indexPathForSelectedRow, let transitionCoordinator = transitionCoordinator {
            transitionCoordinator.animate { context in
                self.tableView.deselectRow(at: selectedIndexPath, animated: true)
            } completion: { context in
                if context.isCancelled {
                    self.tableView.selectRow(at: selectedIndexPath, animated: true, scrollPosition: .none)
                }
            }
        }
    }
    
    func setupCells() {
        guard let cells = cells else { return }
        var snapshot = NSDiffableDataSourceSnapshot<Int, CellContent>()
        
        for section in 0..<cells.count {
            snapshot.appendSections([section])
            snapshot.appendItems(cells[section], toSection: section)
        }
        
        datasource.apply(snapshot, animatingDifferences: false)
    }
}

extension UIStaticTableView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // The first section is weirdly close to the large navigation title, space that out a bit. This also makes it look better in landscape.
        return section == 0 ? 8.0 : 5.0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // Required in order for header height to take effect
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cellContent = datasource.itemIdentifier(for: indexPath) else { return }
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch cellContent.accessoryType {
        case .accessoryType(_, let action):
            switch action {
            case .navigationController(let viewController):
                let vc = viewController()
                present(vc, animated: true)
            case .action(let handler):
                handler()
            case .none:
                break
            }
        default:
            break
        }
    }
}
