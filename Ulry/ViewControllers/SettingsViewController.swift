//
//  SettingsViewController.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/19/22.
//

import UIKit

enum Setting: Hashable {
    case general
    case appearance
    case tip
    case about
    case rate
    
    var icon: UIImage? {
        switch self {
        case .general:
            let configuration = UIImage.SymbolConfiguration.init(paletteColors: [.white, .gray])
            return UIImage(systemName: "ellipsis.circle.fill", withConfiguration: configuration)
        case .appearance:
            let configuration = UIImage.SymbolConfiguration.init(paletteColors: [.white, .purple])
            return UIImage(systemName: "eye.circle.fill", withConfiguration: configuration)
        case .tip:
            let configuration = UIImage.SymbolConfiguration.init(paletteColors: [.white, .orange])
            return UIImage(systemName: "dollarsign.circle.fill", withConfiguration: configuration)
        case .about:
            let configuration = UIImage.SymbolConfiguration.init(paletteColors: [.white, .systemBlue])
            return UIImage(systemName: "info.circle.fill", withConfiguration: configuration)
        case .rate:
            let configuration = UIImage.SymbolConfiguration.init(paletteColors: [.white, .yellow])
            return UIImage(systemName: "star.circle.fill", withConfiguration: configuration)
        }
    }
    
    var title: String? {
        switch self {
        case .general:
            return "General"
        case .appearance:
            return "Appearance"
        case .tip:
            return "Tip Jar"
        case .about:
            return "About"
        case .rate:
            return "Rate Ulry"
        }
    }
}

class SettingsViewController: UIViewController {
    let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    lazy var datasource: UITableViewDiffableDataSource<Int, Setting> = {
        let datasource = UITableViewDiffableDataSource<Int, Setting>(tableView: tableView) { tableView, indexPath, setting in
            let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath)
            var content = UIListContentConfiguration.valueCell()
            content.text = setting.title
            content.textProperties.font = UIFont.rounded(ofSize: 14, weight: .semibold)
            content.image = setting.icon
            cell.contentConfiguration = content
            cell.accessoryType = .disclosureIndicator
            return cell
        }
        
        return datasource
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.title = "Settings"
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .close, primaryAction: UIAction { _ in
          self.dismiss(animated: true)
        })
        
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SettingCell")
        tableView.cellLayoutMarginsFollowReadableWidth = true
        
        view.addSubview(tableView)
        
        addSettings()
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
    
    private func addSettings() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, Setting>()
        
        snapshot.appendSections([0, 1])
        
        snapshot.appendItems([.general, .appearance], toSection: 0)
        snapshot.appendItems([.about, .tip, .rate], toSection: 1)
        
        datasource.apply(snapshot, animatingDifferences: false)
    }
}

extension SettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // The first section is weirdly close to the large navigation title, space that out a bit. This also makes it look better in landscape.
        return section == 0 ? 8.0 : 5.0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // Required in order for header height to take effect
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let setting = datasource.itemIdentifier(for: indexPath) else { return }
        
        // TODO
        switch setting {
        case .general:
            navigationController?.pushViewController(GeneralSettingsViewController(), animated: true)
        case .appearance:
            navigationController?.pushViewController(AppearanceViewController(), animated: true)
        case .about:
            navigationController?.pushViewController(AboutViewController(), animated: true)
        case .tip:
            let tipsVc = TipsViewController()
            // Animation, start with opacity 0
            tipsVc.backgroundView.layer.opacity = 0
            
            tipsVc.discoseButton.addAction(UIAction { _ in
                UIView.animate(
                    withDuration: 0.1,
                    delay: .zero,
                    options: .curveLinear,
                    animations: {
                        tipsVc.backgroundView.layer.opacity = 0
                    },
                    completion: { _ in
                        tipsVc.remove()
                    }
                )
            }, for: .touchUpInside)
            
            tipsVc.add(self, frame: view.bounds)
            
            UIView.animate(withDuration: 0.1, delay: .zero, options: .curveLinear, animations: {
                tipsVc.blur.layer.opacity = 1
                tipsVc.backgroundView.layer.opacity = 1
            })
            
        case .rate:
            let alert = UIAlertController(title: "Not available", message: "Raiting will be available in the first production release", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .cancel))
            self.present(alert, animated: true)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
