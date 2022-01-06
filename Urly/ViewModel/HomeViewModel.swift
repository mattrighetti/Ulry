//
//  HomeViewModel.swift
//  Urly
//
//  Created by Mattia Righetti on 12/25/21.
//

import os
import Combine
import CoreData

public final class HomeViewModel: ObservableObject {
    @Published public private(set) var links = [Link]()
    @Published public private(set) var groups = [Group]()
    @Published public private(set) var tags = [Tag]()
    
    private var cancellable = Set<AnyCancellable>()
    
    init(
        groupsPublisher: AnyPublisher<[Group], Never> = GroupStorage.shared.groups.eraseToAnyPublisher(),
        tagsPublisher: AnyPublisher<[Tag], Never> = TagStorage.shared.tags.eraseToAnyPublisher(),
        linksPublisher: AnyPublisher<[Link], Never> = LinkStorage.shared.links.eraseToAnyPublisher()
    ) {
        groupsPublisher.sink { [unowned self] groups in
            self.groups = groups
        }
        .store(in: &cancellable)
        
        tagsPublisher.sink { [unowned self] tags in
            self.tags = tags
        }
        .store(in: &cancellable)
        
        linksPublisher.sink { [unowned self] links in
            self.links = links
        }
        .store(in: &cancellable)
    }
    
    public func countLinks(by filter: LinkFilter) -> Int? {
        var count: Int? = nil
        do {
            switch filter {
            case .all:
                count = try PersistenceController.shared.container.viewContext.count(for: Link.Request.all.rawValue)
            case .starred:
                count = try PersistenceController.shared.container.viewContext.count(for: Link.Request.starred.rawValue)
            case .unread:
                count = try PersistenceController.shared.container.viewContext.count(for: Link.Request.unread.rawValue)
            default:
                return nil
            }
        } catch {
            print(error)
        }
        
        return count
    }
}
