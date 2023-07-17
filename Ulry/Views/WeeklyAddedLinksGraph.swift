//
//  DatabaseStatsViewController.swift
//  Ulry
//
//  Created by Mattia Righetti on 27/03/23.
//  Copyright © 2023 Mattia Righetti. All rights reserved.
//

import SwiftUI
import Charts
import Account
import LinksDatabase

struct WeeklyAddedLinksGraph: View {

    @State var sevenDaysStats: [LinkAddedPerDay]

    var body: some View {
        if #available(iOS 16.0, *) {
            let max = sevenDaysStats.map { $0.value }.max() ?? 10

            VStack(alignment: .leading) {
                Text("This week")
                    .font(.headline)
                Text("The number of links you added this week")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 2)

                Chart(sevenDaysStats, id: \.self) { item in
                    LineMark(
                        x: .value("Date", String(item.date.dropFirst(5))),
                        y: .value("Value", item.value)
                    )
                    .symbol(.circle)
                    .foregroundStyle(.teal)
                }
                .chartYAxis{
                    AxisMarks(position: .trailing, values: topPaddingData(max: max))
                }
                .frame(height: 240)
            }
            .padding(15)
            .background(Color("list-cell-bg-color"))
        } else {
            Text("Can't be displayed on this iOS version")
                .font(.headline)
        }
    }

    private func topPaddingData(max: Int) -> [Int] {
        let step = max <= 5 ? 1 : max / 5
        let to = max == 0 ? 10 : max + 2 * step
        return stride(from: 0, to: to, by: step).map { $0 }
    }
}

// MARK: - Data Structure
struct LinkAddedPerDay: Hashable {
    var date: String
    var value: Int
}

struct DatabaseStatsViewController_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color("list-bg-color")
            WeeklyAddedLinksGraph(sevenDaysStats: [
                LinkAddedPerDay(date: "2023-11-10", value: 0),
                LinkAddedPerDay(date: "2023-11-11", value: 15),
                LinkAddedPerDay(date: "2023-11-12", value: 0),
                LinkAddedPerDay(date: "2023-11-13", value: 4),
                LinkAddedPerDay(date: "2023-11-14", value: 30),
                LinkAddedPerDay(date: "2023-11-15", value: 10),
                LinkAddedPerDay(date: "2023-11-16", value: 1)
            ]).preferredColorScheme(.dark)
        }
    }
}
