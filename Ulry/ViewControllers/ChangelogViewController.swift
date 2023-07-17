//
//  ChangelogViewController.swift
//  Ulry
//
//  Created by Mattia Righetti on 10/26/22.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import SwiftUI

struct Release: Hashable, Decodable {
    var version: String
    var description: String?
    var changes: [String]?
}

struct ChangelogViewController: View {
    
    private var releases: [Release] = {
        guard
            let path = Bundle.main.path(forResource: "changelog", ofType: "json"),
            let data = try? Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe),
            let res = try? JSONDecoder().decode([Release].self, from: data)
        else {
            return []
        }

        return res
    }()
    
    var body: some View {
        List {
            AppHeader()
                .padding(.bottom, 20)
                .listRowSeparator(.hidden)
                .padding(.top, 20)
            ForEach(releases, id: \.self) { release in
                ReleaseView(version: release.version, description: release.description, changelogs: release.changes)
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
    }
}

struct AppHeader: View {
    var body: some View {
        HStack() {
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 25.0)
                    .foregroundColor(.gray.opacity(0.5))
                    .frame(width: 105, height: 105)
                Image("thumb-default")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .cornerRadius(23.0)
                    .padding(.horizontal, 10)
            }

            VStack(alignment: .leading) {
                Text("What's new in")
                Text("Ulry")
            }
            .font(.system(size: 25, weight: .bold))

            Spacer()
        }
    }
}

struct ReleaseView: View {
    var version: String
    var description: String?
    var changelogs: [String]?
    
    var body: some View {
        VStack(alignment: .leading) {
            Divider()

                Text(version)
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 10)
                    .padding(.bottom, 3)

                if let description = description {
                    Text(description)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 3)
                }

            if let changelogs = changelogs {
                ForEach(changelogs, id: \.self) { changelog in
                    HStack {
                        Text("-")
                        Text((try! AttributedString(markdown: changelog)))
                            .font(.body)
                            .padding(.bottom, 1)
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct ChangelogViewController_Previews: PreviewProvider {
    static var previews: some View {
        ChangelogViewController()
            .preferredColorScheme(.dark)
    }
}
