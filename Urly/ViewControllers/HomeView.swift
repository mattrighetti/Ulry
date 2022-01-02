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
    @StateObject private var viewModel = HomeViewModel()
    
    private var cancellables = Set<AnyCancellable>()
    
    let mainSection = [
        MainFolder(name: "All", iconName: "list.bullet.circle.fill", color: .gray),
        MainFolder(name: "Unread", iconName: "archivebox.circle.fill", color: .blue),
        MainFolder(name: "Starred", iconName: "star.circle.fill", color: .yellow)
    ]
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    Section(header: Text("General").sectionTitle()) {
                        ForEach(mainSection, id: \.self) { item in
                            NavigationLink {
                                LinkList()
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
                            ForEach(viewModel.groups, id: \.id) { datum in
                                NavigationLink {
                                    //LinkList(selection: .folder(datum))
                                } label: {
                                    Label(title: {
                                        Text(datum.name)
                                            .font(.system(size: 15, weight: .medium, design: .rounded))
                                    }, icon: {
                                        ZStack {
                                            Color(hex: datum.colorHex)!
                                                .clipShape(Circle())
                                            Image(systemName: datum.iconName)
                                                .font(.system(size: 10))
                                                .foregroundColor(.white)
                                        }.frame(width: 25, height: 25)
                                    })
                                }
                            }
                        }
                    }
                    
                    if !viewModel.tags.isEmpty {
                        Section(header: Text("Tags").sectionTitle()) {
                            ForEach(viewModel.tags, id: \.id) { datum in
                                NavigationLink {
                                    //LinkList(selection: .tag(datum))
                                } label: {
                                    Label(title: {
                                        Text(datum.name)
                                            .font(.system(size: 15, weight: .medium, design: .rounded))
                                    }, icon: {
                                        Color(hex: datum.colorHex)!
                                            .clipShape(Circle())
                                    })
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
