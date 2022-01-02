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
    
    var body: some View {
        List {
            ForEach(viewModel.links, id: \.id) { link in
                Text("\(link.url!)")
            }
        }
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
