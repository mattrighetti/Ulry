//
//  AppearanceViewController.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/19/22.
//

import UIKit

class AppearanceViewController: UIViewController {
    let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    lazy var datasource: UITableViewDiffableDataSource<Int, String> = {
        let datasource = UITableViewDiffableDataSource<Int, String>(tableView: tableView) { tableView, indexPath, itemIdentifier in
            let cell = tableView.dequeueReusableCell(withIdentifier: "AppearanceCell", for: indexPath)
            var contentConfig = cell.defaultContentConfiguration()
            // TODO
            cell.contentConfiguration = contentConfig
            cell.selectionStyle = .none
            return cell
        }
        
        return datasource
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.title = "Appearance"
        
        tableView.delegate = self
        tableView.register(UILinkTableViewCell.self, forCellReuseIdentifier: "AppearanceCell")
        tableView.cellLayoutMarginsFollowReadableWidth = true
        
        view.addSubview(tableView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
}

extension AppearanceViewController: UITableViewDelegate {
    
}
