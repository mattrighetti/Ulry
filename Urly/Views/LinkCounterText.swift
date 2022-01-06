//
//  LinkCounterText.swift
//  Urly
//
//  Created by Mattia Righetti on 1/5/22.
//

import SwiftUI

struct LinkCounterText: View {
    var filter: LinkFilter
    
    var numText: String? {
        var count: Int? = nil
        do {
            switch filter {
            case .all:
                count = try PersistenceController.shared.container.viewContext.count(for: Link.Request.all.rawValue)
            case .starred:
                count = try PersistenceController.shared.container.viewContext.count(for: Link.Request.starred.rawValue)
            case .unread:
                count = try PersistenceController.shared.container.viewContext.count(for: Link.Request.unread.rawValue)
            case .group(let group):
                count = try PersistenceController.shared.container.viewContext.count(for: Link.Request.folder(group).rawValue)
            case .tag(let tag):
                count = try PersistenceController.shared.container.viewContext.count(for: Link.Request.tag(tag).rawValue)
            }
        } catch {
            print(error)
        }
        
        if let count = count {
            if count == 0 {
                return nil
            } else {
                return String(count)
            }
        } else {
            return nil
        }
    }
    
    var body: some View {
        if let numText = numText {
            Text(numText)
                .foregroundColor(.white)
                .font(Font.system(size: 10, weight: .semibold, design: .rounded))
                .padding(5)
                .background(.gray.opacity(0.4))
                .clipShape(Capsule())
        } else {
            EmptyView()
        }
    }
}
