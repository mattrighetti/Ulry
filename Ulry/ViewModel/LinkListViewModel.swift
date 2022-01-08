//
//  LinkListViewModel.swift
//  Urly
//
//  Created by Mattia Righetti on 1/2/22.
//

import Combine
import SwiftUI

public enum LinkFilter {
    case all
    case starred
    case unread
    case group(Group)
    case tag(Tag)
}

public final class LinkListViewModel: ObservableObject {
    @Published public private(set) var links = [Link]()
    
    private var cancellable = Set<AnyCancellable>()
    
    init(
        linksPublisher: AnyPublisher<[Link], Never> = LinkStorage.shared.links.eraseToAnyPublisher()
    ) {
        linksPublisher.sink { [unowned self] links in
            self.links = links
        }
        .store(in: &cancellable)
    }
    
    public func getLinks(by filter: LinkFilter) {
        let links: [Link]
        switch filter {
        case .all:
            links = try! PersistenceController.shared.container.viewContext.fetch(Link.Request.all.rawValue)
        case .starred:
            links = try! PersistenceController.shared.container.viewContext.fetch(Link.Request.starred.rawValue)
        case .unread:
            links = try! PersistenceController.shared.container.viewContext.fetch(Link.Request.unread.rawValue)
        case .tag(let tag):
            links = try! PersistenceController.shared.container.viewContext.fetch(Link.Request.tag(tag).rawValue)
        case .group(let group):
            links = try! PersistenceController.shared.container.viewContext.fetch(Link.Request.folder(group).rawValue)
        }
        
        self.links = links
    }
}
