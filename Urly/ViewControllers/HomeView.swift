//
//  HomeView.swift
//  Urly
//
//  Created by Mattia Righetti on 12/23/21.
//

import SwiftUI
import Combine
import CoreData

struct HomeView: View {
    @StateObject private var sheet = SheetState()
    @State private var showAddLinkPopup: Bool = false
    @State private var showConfirmationDialog = false
    @StateObject private var viewModel = HomeViewModel()
    
    private var cancellables = Set<AnyCancellable>()
    
    let mainSection = [
        MainFolder(name: "All", iconName: "list.bullet.circle.fill", color: .gray, filter: .all),
        MainFolder(name: "Unread", iconName: "archivebox.circle.fill", color: .blue, filter: .unread),
        MainFolder(name: "Starred", iconName: "star.circle.fill", color: .yellow, filter: .starred)
    ]
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    Section(header: Text("General").sectionTitle()) {
                        ForEach(mainSection, id: \.self) { item in
                            NavigationLink {
                                LinkList(filter: item.filter)
                            } label: {
                                Label(title: {
                                    HStack {
                                        Text(item.name)
                                            .font(.system(size: 15, weight: .medium, design: .rounded))
                                        Spacer()
                                        LinkCounterText(filter: item.filter)
                                    }
                                }, icon: {
                                    Image(systemName: item.iconName)
                                        .font(.system(size: 12))
                                        .foregroundColor(.white)
                                        .padding(5)
                                        .background(Color(hex: "#333333").opacity(0.4))
                                        .clipShape(Circle())
                                        .frame(width: 25, height: 25)
                                })
                            }
                        }
                        
                        NavigationLink {
                            AddLinkViewController()
                        } label: {
                            Label(title: {
                                Text("Add link")
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                            }, icon: {
                                ZStack {
                                    Color(hex: "#333333")!
                                        .clipShape(Circle())
                                    Image(systemName: "link.circle.fill")
                                        .font(.system(size: 12))
                                }
                                .frame(width: 25, height: 25)
                            })
                            .foregroundColor(.blue)
                        }
                    }
                    
                    if !viewModel.groups.isEmpty {
                        Section(header: Text("Groups").sectionTitle()) {
                            ForEach(viewModel.groups, id: \.id) { group in
                                NavigationLink {
                                    LinkList(filter: .group(group))
                                } label: {
                                    Label(title: {
                                        Text(group.name)
                                            .font(.system(size: 15, weight: .medium, design: .rounded))
                                        Spacer()
                                        LinkCounterText(filter: .group(group))
                                    }, icon: {
                                        ZStack {
                                            Color(hex: group.colorHex)!
                                                .clipShape(Circle())
                                            Image(systemName: group.iconName)
                                                .font(.system(size: 10))
                                                .foregroundColor(.white)
                                        }.frame(width: 25, height: 25)
                                    })
                                }
                                .swipeActions {
                                    Button(
                                        role: .destructive,
                                        action: { showConfirmationDialog.toggle() }
                                    ) {
                                        Image(systemName: "trash")
                                    }
                                    Button(
                                        action: { showConfirmationDialog.toggle() }
                                    ) {
                                        Image(systemName: "square.and.pencil")
                                    }
                                }
                                .confirmationDialog(
                                    "Are you sure you want to delete foder \(group.name)?",
                                    isPresented: $showConfirmationDialog,
                                    titleVisibility: .visible
                                ) {
                                    Button("Yes", role: .destructive) {
                                        GroupStorage.shared.delete(group)
                                    }
                                }
                            }
                        }
                    }
                    
                    if !viewModel.tags.isEmpty {
                        Section(header: Text("Tags").sectionTitle()) {
                            ForEach(viewModel.tags, id: \.id) { tag in
                                NavigationLink {
                                    LinkList(filter: .tag(tag))
                                } label: {
                                    Label(title: {
                                        Text(tag.name)
                                            .font(.system(size: 15, weight: .medium, design: .rounded))
                                        Spacer()
                                        LinkCounterText(filter: .tag(tag))
                                    }, icon: {
                                        Color(hex: tag.colorHex)!
                                            .clipShape(Circle())
                                    })
                                }
                                .swipeActions {
                                    Button(
                                        role: .destructive,
                                        action: { showConfirmationDialog.toggle() }
                                    ) {
                                        Image(systemName: "trash")
                                    }
                                    Button(
                                        action: { showConfirmationDialog.toggle() }
                                    ) {
                                        Image(systemName: "square.and.pencil")
                                    }
                                }
                                .confirmationDialog(
                                    "Are you sure you want to delete tag \(tag.name)?",
                                    isPresented: $showConfirmationDialog,
                                    titleVisibility: .visible
                                ) {
                                    Button("Yes", role: .destructive) {
                                        TagStorage.shared.delete(tag)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .sheet(
                isPresented: $sheet.isShowing,
                onDismiss: {
                    sheet.addMode = nil
                },
                content: {
                    AddCategoryView(mode: sheet.addMode!)
                }
            )
            
            .navigationTitle("Urly")
            .toolbar {
                ToolbarItem {
                    NavigationLink {
                        AddLinkViewController()
                    } label: {
                        Image(systemName: "link.circle")
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    HStack {
                        Button {
                            sheet.addMode = .folder
                        } label: {
                            Text("\(Image(systemName: "folder.circle")) Add group")
                                .font(.system(size: 15))
                        }
                        Spacer()
                        Button {
                            sheet.addMode = .tag
                        } label: {
                            Text("\(Image(systemName: "tag.circle")) Add tag")
                                .font(.system(size: 15))
                        }
                    }
                }
            }
        }
    }
}

struct LinkCounterText: View {
    var filter: LinkFilter
    
    var emptyText: String = "Empty"
    
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
        }
    }
}

fileprivate class SheetState: ObservableObject {
    @Published var isShowing: Bool = false
    @Published var addMode: PickerMode? = nil {
        didSet {
            isShowing = addMode != nil
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView().preferredColorScheme(.dark)
    }
}
