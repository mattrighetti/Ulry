//
//  LinkList.swift
//  Urly
//
//  Created by Mattia Righetti on 1/2/22.
//

import SwiftUI
import CoreData

fileprivate class SheetState: ObservableObject {
    @Published var isShowing: Bool = false
    @Published var link: Link? = nil {
        didSet {
            isShowing = link != nil
        }
    }
}

struct LinkList: View {
    var filter: LinkFilter
    @StateObject private var sheet = SheetState()
    @StateObject private var viewModel = LinkListViewModel()
    @State private var presentActionSheet = false
    @State private var showConfirmationDialog = false
    
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
            if let selectionDescription = selectionDescription {
                Text(selectionDescription)
            }
            
            if isListEmpty {
                Text("There is no link in this category")
                    .padding(.top, 20)
            } else {
                ForEach(viewModel.links, id: \.id) { link in
                    LinkCellView(link: link, infoPressAction: {
                        sheet.link = link
                    })
                }
            }
        }
        .navigationTitle(title)
        .onAppear {
            viewModel.getLinks(by: filter)
        }
        .sheet(
            isPresented: $sheet.isShowing,
            onDismiss: {
                sheet.link = nil
            },
            content: {
                LinkDetailView(link: sheet.link!)
            }
        )
    }
}

struct LinkList_Previews: PreviewProvider {
    static var previews: some View {
        LinkList(filter: .all)
    }
}
