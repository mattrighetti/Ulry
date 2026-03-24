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
import LinksDatabase

final class UlryInfoViewController: UIViewController {

    var account: Account!

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Stats"
        navigationItem.largeTitleDisplayMode = .never

        let stats = (try? account.fetchStats()) ?? []
        let weeklyData = computeWeeklyData()
        let dbSize = account.getDatabaseSize()
        let imagesSize = ImageStorage.shared.getTotalImageOccupiedStorage()

        let hostingVC = UIHostingController(rootView: InfoView(
            stats: stats,
            databaseSize: dbSize,
            imagesSize: imagesSize,
            weeklyData: weeklyData
        ))
        hostingVC.view.backgroundColor = UIColor(named: "list-bg-color")

        addChild(hostingVC)
        hostingVC.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingVC.view)
        NSLayoutConstraint.activate([
            hostingVC.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        hostingVC.didMove(toParent: self)
    }

    private func computeWeeklyData() -> [LinkAddedPerDay] {
        guard let dbResult = try? account.fetchLinksAddedInLastSevenDays() else { return [] }
        var dates = lastSevenDaysStrings().map { LinkAddedPerDay(date: $0, value: 0) }
        for (j, date) in dates.enumerated() {
            guard let i = dbResult.firstIndex(where: { $0.0 == date.date }) else { continue }
            dates[j].value += dbResult[i].1
        }
        return dates
    }

    private func lastSevenDaysStrings() -> [String] {
        let calendar = Calendar.current
        let today = Date()
        var dates: [String] = []
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            dates.append(date.getFormattedDate(format: "YYYY-MM-dd"))
        }
        return dates.reversed()
    }
}

// MARK: - SwiftUI Info View

private struct InfoView: View {
    let stats: [DbStat]
    let databaseSize: String
    let imagesSize: String
    let weeklyData: [LinkAddedPerDay]

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                sectionHeader("Overview")

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(Array(stats.enumerated()), id: \.offset) { _, stat in
                        StatCard(stat: stat)
                    }
                }
                .padding(.bottom, 10)

                sectionHeader("This Week")

                WeeklyAddedLinksGraph(sevenDaysStats: weeklyData)
                    .padding(.bottom, 10)

                sectionHeader("Storage")

                VStack(spacing: 0) {
                    StorageRow(icon: "cylinder.split.1x2.fill", title: "Database", value: databaseSize)
                    Divider().padding(.leading, 16)
                    StorageRow(icon: "photo.on.rectangle", title: "Images", value: imagesSize)
                }
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.bottom, 6)

                Text("Storage figures may differ from the occupied space shown in Settings > iPhone Storage.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
    }

    @ViewBuilder
    private func sectionHeader(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)
            .padding(.top, 8)
            .padding(.bottom, 2)
    }
}

private struct StatCard: View {
    let stat: DbStat

    private var gradientColors: [Color] {
        switch stat.0 {
        case .countAll:
            return [Color(decimalRed: 142, green: 118, blue: 212), Color(decimalRed: 88, green: 66, blue: 165)]
        case .countUnread:
            return [Color(decimalRed: 212, green: 140, blue: 76), Color(decimalRed: 172, green: 88, blue: 44)]
        case .countStarred:
            return [Color(decimalRed: 228, green: 116, blue: 86), Color(decimalRed: 188, green: 66, blue: 66)]
        case .countArchived:
            return [Color(decimalRed: 128, green: 133, blue: 158), Color(decimalRed: 88, green: 92, blue: 116)]
        }
    }

    private var icon: String {
        switch stat.0 {
        case .countAll:      return "tray.full.fill"
        case .countUnread:   return "circle.fill"
        case .countStarred:  return "star.fill"
        case .countArchived: return "archivebox.fill"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))

            Spacer()

            Text("\(stat.1)")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(stat.0.rawValue)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.72))
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 108, alignment: .leading)
        .background(
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: gradientColors[1].opacity(0.38), radius: 10, y: 5)
    }
}

private struct StorageRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .frame(width: 28)
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .background(Color("list-cell-bg-color"))
    }
}
