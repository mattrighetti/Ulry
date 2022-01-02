//
//  HomeViewModel.swift
//  Urly
//
//  Created by Mattia Righetti on 12/25/21.
//

import Combine
import CoreData

public final class HomeViewModel: ObservableObject {
    @Published public private(set) var links = [Link]()
    @Published public private(set) var groups = [Group]()
    @Published public private(set) var tags = [Tag]()
    
    private var cancellable = Set<AnyCancellable>()
    
    init(
        groupsPublisher: AnyPublisher<[Group], Never> = GroupStorage.shared.groups.eraseToAnyPublisher(),
        tagsPublisher: AnyPublisher<[Tag], Never> = TagStorage.shared.tags.eraseToAnyPublisher()
    ) {
        groupsPublisher.sink { [unowned self] groups in
            self.groups = groups
            print(groups)
        }
        .store(in: &cancellable)
        
        tagsPublisher.sink { [unowned self] tags in
            self.tags = tags
            print(tags)
        }
        .store(in: &cancellable)
    }
}
