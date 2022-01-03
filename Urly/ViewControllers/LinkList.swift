//
//  LinkList.swift
//  Urly
//
//  Created by Mattia Righetti on 1/2/22.
//

import SwiftUI
import CoreData

struct LinkList: View {
    var filter: LinkFilter?
    @StateObject private var viewModel = LinkListViewModel()
    
    var title: String {
        switch filter {
        case .all:
            return "All"
        case .starred:
            return "Starred"
        case .unread:
            return "Unread"
        case .group(let group):
            return group.name
        case .tag(let tag):
            return tag.name
        default:
            return "Default"
        }
    }
    
    var selectionDescription: String? {
        switch filter {
        case .tag(let tag):
            return tag.description_.isEmpty ? nil : tag.description_
        default:
            return nil
        }
    }
    
    var isListEmpty: Bool {
        viewModel.links.isEmpty
    }
    
    var body: some View {
        ScrollView {
            if selectionDescription != nil {
                Text(selectionDescription!)
            }
            
            if isListEmpty {
                Text("There is no link in this category")
            } else {
                ForEach(viewModel.links, id: \.id) { link in
                    LinkCellView(link: link)
                }
            }
        }
        .navigationTitle(title)
        .onAppear {
            viewModel.getLinks(by: filter!)
        }
    }
}

struct LinkList_Previews: PreviewProvider {
    static var previews: some View {
        LinkList()
    }
}
