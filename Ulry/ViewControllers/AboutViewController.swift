//
//  AboutViewController.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/19/22.
//

import UIKit

enum AboutOption: Hashable {
    // TODO
}

class AboutViewController: UIViewController {
    let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    lazy var datasource: UITableViewDiffableDataSource<Int, AboutOption> = {
        let datasource = UITableViewDiffableDataSource<Int, AboutOption>(tableView: tableView) { tableView, indexPath, option in
            let cell = tableView.dequeueReusableCell(withIdentifier: "AboutCell", for: indexPath)
            var contentConfig = cell.defaultContentConfiguration()
            cell.contentConfiguration = contentConfig
            cell.selectionStyle = .none
            return cell
        }
        
        return datasource
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.title = "About"
        
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "AboutCell")
        tableView.cellLayoutMarginsFollowReadableWidth = true
        
        view.addSubview(tableView)
        
        setup()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
    
    private func setup() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, AboutOption>()
        
        snapshot.appendSections([0])
        // TODO
        
        datasource.apply(snapshot, animatingDifferences: false)
    }
}

extension AboutViewController: UITableViewDelegate {
    
}
