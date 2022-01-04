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
                                    Text(item.name)
                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                }, icon: {
                                    ZStack {
                                        Color(hex: "#333333")!
                                            .clipShape(Circle())
                                        Image(systemName: item.iconName)
                                            .font(.system(size: 10))
                                            .foregroundColor(.white)
                                    }.frame(width: 25, height: 25)
                                })
                            }
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
                    IconColorPickerView(mode: sheet.addMode!)
                }
            )
            
            .navigationTitle("Urly")
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    HStack {
                        Button {
                            sheet.addMode = .folder
                        } label: {
                            Image(systemName: "folder.fill.badge.plus")
                            .bottomBarButton(
                                darkColors: (.gray, Color(hex: "#333333")!),
                                lightColors: (.blue, .yellow)
                            )
                        }
                        Button {
                            sheet.addMode = .tag
                        } label: {
                            Image(systemName: "tag.fill")
                            .bottomBarButton(
                                darkColors: (.gray, Color(hex: "#333333")!),
                                lightColors: (.blue, .yellow)
                            )
                        }
                        
                        Spacer()
                        
                        NavigationLink {
                            AddLinkViewController()
                        } label: {
                            Image(systemName: "link.badge.plus")
                                .bottomBarButton(
                                    darkColors: (.gray, Color(hex: "#333333")!),
                                    lightColors: (.blue, .yellow)
                                )
                        }
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
        HomeView().preferredColorScheme(.dark)
    }
}
