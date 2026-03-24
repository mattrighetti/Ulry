//
//  WeeklyAddedLinksGraph.swift
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

    let sevenDaysStats: [LinkAddedPerDay]

    private var totalThisWeek: Int {
        sevenDaysStats.reduce(0) { $0 + $1.value }
    }

    var body: some View {
        if #available(iOS 16.0, *) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text("\(totalThisWeek)")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                    Text(totalThisWeek == 1 ? "link" : "links")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 2)
                    Spacer()
                }
                Text("added in the last 7 days")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 18)

                Chart(sevenDaysStats, id: \.self) { item in
                    BarMark(
                        x: .value("Day", dayLabel(from: item.date)),
                        y: .value("Links", item.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(decimalRed: 145, green: 122, blue: 215),
                                Color(decimalRed: 90, green: 68, blue: 168)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(6)
                }
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                        AxisGridLine()
                            .foregroundStyle(Color.secondary.opacity(0.2))
                        AxisValueLabel()
                            .foregroundStyle(Color.secondary)
                            .font(.system(size: 11))
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .foregroundStyle(Color.secondary)
                            .font(.system(size: 11))
                    }
                }
                .frame(height: 160)
            }
            .padding(16)
            .background(Color("list-cell-bg-color"))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private func dayLabel(from dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else {
            return String(dateString.dropFirst(5))
        }
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEE"
        return dayFormatter.string(from: date)
    }
}

// MARK: - Data Structure

struct LinkAddedPerDay: Hashable {
    var date: String
    var value: Int
}

struct WeeklyAddedLinksGraph_Previews: PreviewProvider {
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
            ])
            .padding()
            .preferredColorScheme(.dark)
        }
    }
}
