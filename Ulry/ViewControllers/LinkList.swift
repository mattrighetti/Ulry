//
//  LinkList.swift
//  Urly
//
//  Created by Mattia Righetti on 1/2/22.
//

import SwiftUI
import CoreData

struct LinkList: View {
    var filter: Category
    var navigationController: UINavigationController?
    
    @StateObject private var viewModel = LinkListViewModel()
    @State private var presentActionSheet = false
    @State private var showConfirmationDialog = false
    
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
                VStack {
                    LottieView(animationName: "empty-box", loopMode: .playOnce, animationSpeed: 1.0)
                        .frame(width: 150, height: 150)
                    
                    Text("Empty")
                        .font(.system(.headline, design: .rounded))
                }
            } else {
                ForEach(viewModel.links, id: \.id) { link in
                    LinkCellView(link: link, infoPressAction: {
                        infoSheet(for: link)
                    })
                }
            }
        }
        .onAppear {
            viewModel.getLinks(by: filter)
        }
    }
    
    private func infoSheet(for link: Link) {
        let vc = UIHostingController(rootView: LinkDetailView(link: link))
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.preferredCornerRadius = 35.0
            sheet.largestUndimmedDetentIdentifier = .medium
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
            sheet.prefersGrabberVisible = true
        }
        navigationController?.present(vc, animated: true, completion: nil)
    }
}

struct LinkList_Previews: PreviewProvider {
    static var previews: some View {
        LinkList(filter: .all)
    }
}
