//
//  HomeView.swift
//  Urly
//
//  Created by Mattia Righetti on 12/23/21.
//

import os
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
        MainFolder(name: "All", iconName: "list.bullet", color: .gray, filter: .all),
        MainFolder(name: "Unread", iconName: "archivebox", color: .blue, filter: .unread),
        MainFolder(name: "Starred", iconName: "star", color: .yellow, filter: .starred)
    ]
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    MainSection()
                    GroupSection()
                    TagSection()
                }
            }
            .sheet(
                isPresented: $sheet.isShowing,
                onDismiss: { sheet.addMode = nil },
                content: { AddCategoryView(mode: sheet.addMode!) }
            )
            
            .navigationTitle("Urly")
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    HStack {
                        Button {
                            sheet.addMode = .group
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
    
    @ViewBuilder
    private func MainSection() -> some View {
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
                            LinkCounterText(count: viewModel.countLinks(by: item.filter))
                        }
                    }, icon: {
                        Image(systemName: item.iconName)
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                            .padding(5)
                            .background(item.color.opacity(0.4))
                            .clipShape(Circle())
                            .frame(width: 25, height: 25)
                    })
                }
            }
            
            NavigationLink(destination: AddLinkViewController(configuration: .new)) {
                Label(title: {
                    Text("Add link")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                }, icon: {
                    ZStack {
                        Color(hex: "#333333")!
                            .clipShape(Circle())
                        Image(systemName: "link")
                            .font(.system(size: 12))
                    }
                    .frame(width: 25, height: 25)
                })
                .foregroundColor(.blue)
            }
        }
    }
    
    @ViewBuilder
    private func GroupSection() -> some View {
        if !viewModel.groups.isEmpty {
            Section(header: Text("Groups").sectionTitle()) {
                ForEach(viewModel.groups, id: \.self) { group in
                    NavigationLink {
                        LinkList(filter: .group(group))
                    } label: {
                        Label(title: {
                            Text(group.name)
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                            Spacer()
                            LinkCounterText(count: group.links?.count)
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
                            action: {
                                withAnimation {
                                    GroupStorage.shared.delete(group)
                                }
                            }
                        ) {
                            Image(systemName: "trash")
                        }
                        
                        Button(
                            action: {
                                sheet.addMode = .editGroup(group)
                            }
                        ) {
                            Image(systemName: "square.and.pencil")
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func TagSection() -> some View {
        if !viewModel.tags.isEmpty {
            Section(header: Text("Tags").sectionTitle()) {
                ForEach(viewModel.tags, id: \.self) { tag in
                    NavigationLink {
                        LinkList(filter: .tag(tag))
                    } label: {
                        Label(title: {
                            Text(tag.name)
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                            Spacer()
                            LinkCounterText(count: tag.links?.count)
                        }, icon: {
                            Color(hex: tag.colorHex)!
                                .clipShape(Circle())
                        })
                    }
                    .swipeActions {
                        Button(action: { withAnimation { TagStorage.shared.delete(id: tag.id) } }) {
                            Image(systemName: "trash")
                        }
                        .tint(.red)
                        
                        Button(action: { sheet.addMode = .editTag(tag) }) {
                            Image(systemName: "square.and.pencil")
                        }
                        .tint(.blue)
                    }
                }
            }
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
        HomeView()
            .preferredColorScheme(.dark)
    }
}
