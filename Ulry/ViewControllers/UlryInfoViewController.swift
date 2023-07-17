//
//  UlryInfoViewController.swift
//  Ulry
//
//  Created by Mattia Righetti on 17/04/23.
//  Copyright © 2023 Mattia Righetti. All rights reserved.
//

import UIKit
import SwiftUI
import Account

fileprivate enum DataKind: Hashable {
    case data(String, String)
    case dataWithImage(String,String,String)
    case graph([LinkAddedPerDay])
}

final class UlryInfoViewController: UIViewController {

    var account: Account!

    private var collectionView: UICollectionView = {
        let layout = UICollectionViewCompositionalLayout { (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            var configuration: UICollectionLayoutListConfiguration

            switch sectionIndex {
            case 0:
                configuration = UICollectionLayoutListConfiguration.withCustomBackground(appearance: .insetGrouped)
                configuration.headerMode = .supplementary
                configuration.footerMode = .none
            case 1:
                configuration = UICollectionLayoutListConfiguration.withCustomBackground(appearance: .insetGrouped)
                configuration.headerMode = .supplementary
                configuration.footerMode = .supplementary
            case 2:
                configuration = UICollectionLayoutListConfiguration.withCustomBackground(appearance: .plain)
                configuration.showsSeparators = false
                configuration.headerMode = .none
                configuration.footerMode = .none
            default:
                fatalError()
            }

            return NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: layoutEnvironment)
        }

        let collectionview = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionview.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        collectionview.translatesAutoresizingMaskIntoConstraints = false
        return collectionview
    }()

    private lazy var datasource: UICollectionViewDiffableDataSource<Int, DataKind> = {

        // MARK: - Cell registrations

        let aboutCellConfiguration = UICollectionView.CellRegistration<UICollectionViewCellCustomBackground, (String, String)> { cell, indexPath, tuple in
            var configuration = UIListContentConfiguration.valueCell()
            configuration.text = tuple.0
            configuration.secondaryText = tuple.1
            configuration.prefersSideBySideTextAndSecondaryText = true
            cell.contentConfiguration = configuration
        }

        let storageCellConfiguration = UICollectionView.CellRegistration<UICollectionViewCellCustomBackground, (String, String, String)> { [weak self] cell, indexPath, tuple in
            var configuration = UIListContentConfiguration.valueCell()
            configuration.text = tuple.1
            configuration.secondaryText = tuple.2
            configuration.prefersSideBySideTextAndSecondaryText = true
            configuration.image = UIImage(systemName: tuple.0)
            configuration.imageProperties.tintColor = .label

            cell.contentConfiguration = configuration
        }

        let graphCellConfiguration = UICollectionView.CellRegistration<SwiftUICollectionViewCell, [LinkAddedPerDay]> { [weak self] cell, indexPath, data in
            cell.host(UIHostingController(rootView: WeeklyAddedLinksGraph(sevenDaysStats: data)))
        }

        var datasource = UICollectionViewDiffableDataSource<Int, DataKind>(collectionView: collectionView) { collectionView, indexPath, dataKind in
            switch dataKind {
            case .data(let title, let value):
                return collectionView.dequeueConfiguredReusableCell(using: aboutCellConfiguration, for: indexPath, item: (title, value))
            case .dataWithImage(let title, let value, let image):
                return collectionView.dequeueConfiguredReusableCell(using: storageCellConfiguration, for: indexPath, item: (title, value, image))
            case .graph(let data):
                return collectionView.dequeueConfiguredReusableCell(using: graphCellConfiguration, for: indexPath, item: data)
            }
        }

        let headerRegistration: UICollectionView.SupplementaryRegistration<UICollectionViewListCell> = .init(elementKind: UICollectionView.elementKindSectionHeader) { [unowned self] supplementaryView, _, indexPath in
            var config = supplementaryView.defaultContentConfiguration()
            config.textProperties.font = UIFont.systemFont(ofSize: 13, weight: .regular)
            config.textProperties.color = .secondaryLabel

            switch indexPath.section {
            case 0:
                config.text = "About links"
            case 1:
                config.text = "Storage info"
            default:
                fatalError("cannot run header registration for this indexPath: \(indexPath)")
            }

            supplementaryView.contentConfiguration = config
        }

        let footerRegistration: UICollectionView.SupplementaryRegistration<UICollectionViewListCell> = .init(elementKind: UICollectionView.elementKindSectionFooter) { [unowned self] supplementaryView, _, indexPath in
            var config = supplementaryView.defaultContentConfiguration()
            config.textProperties.font = UIFont.preferredFont(for: .caption1, weight: .regular)
            config.textProperties.color = .secondaryLabel

            switch indexPath.section {
            case 1:
                config.text = "Storage info could be different from the app's occupied space that you see if you navigate to Settings > iPhone/iPad Storage."
            default:
                fatalError("cannot run header registration for this indexPath: \(indexPath)")
            }

            supplementaryView.contentConfiguration = config
        }

        datasource.supplementaryViewProvider = { [weak self] cv, kind, indexPath -> UICollectionReusableView? in
            if kind == UICollectionView.elementKindSectionHeader {
                return cv.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
            } else {
                return cv.dequeueConfiguredReusableSupplementary(using: footerRegistration, for: indexPath)
            }
        }

        return datasource
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Info"

        navigationItem.largeTitleDisplayMode = .never

        collectionView.delegate = self
        view.addSubview(collectionView)

        setupDatasource()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.frame = view.bounds
    }

    private func setupDatasource() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, DataKind>()
        snapshot.appendSections([0,1,2])

        let aboutStats = try? account.fetchStats()
        let lastSevenDays = getvalues()

        snapshot.appendItems([
            .dataWithImage("cylinder.split.1x2.fill", "Database", account.getDatabaseSize()),
            .dataWithImage("photo.on.rectangle", "Images", ImageStorage.shared.getTotalImageOccupiedStorage())
        ], toSection: 1)

        if let aboutStats = aboutStats {
            snapshot.appendItems(aboutStats.map { .data($0.0.rawValue, String($0.1)) }, toSection: 0)
        }

        snapshot.appendItems([.graph(lastSevenDays)], toSection: 2)

        datasource.apply(snapshot, animatingDifferences: false)
    }

    private func getvalues() -> [LinkAddedPerDay] {
        guard let dbResult = try? account.fetchLinksAddedInLastSevenDays() else { return [] }
        var dates = lastSevenDaysStrings().map({ LinkAddedPerDay(date: $0, value: 0) })

        for (j, date) in dates.enumerated() {
            guard let i = dbResult.firstIndex(where: { $0.0 == date.date }) else { continue }
            dates[j].value += dbResult[i].1
        }

        return dates
    }

    private func lastSevenDaysStrings() -> [String] {
        let calendar = Calendar.current
        let today = Date()
        let sevenDaysAgo = calendar.date(byAdding: .day, value: 0, to: today)!
        var dates: [String] = []

        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -i, to: sevenDaysAgo)!
            dates.append(date.getFormattedDate(format: "YYYY-MM-dd"))
        }

        return dates.reversed()
    }
}

extension UlryInfoViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return false
    }
}
