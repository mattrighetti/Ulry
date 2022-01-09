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
    
    public func getLinks(by filter: Category) {
        self.links = LinkStorage.shared.getLinks(by: filter)
    }
}
