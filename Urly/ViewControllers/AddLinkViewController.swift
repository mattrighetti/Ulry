//
//  AddLinkViewController.swift
//  Urly
//
//  Created by Mattia Righetti on 12/25/21.
//

import os
import Combine
import SwiftUI

struct AddLinkViewController: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State private var link: String = ""
    @State private var selectedFolder: Group? = nil
    @State private var selectedTags: [Tag] = []
    @State private var tags: [Tag] = []
    @State private var groups: [Group] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    private var selectedTagsStringValue: String {
        selectedTags.isEmpty ? "None" : "X tags"
    }
    
    private var selectedFolderStringValue: String {
        selectedFolder == nil ? "None" : "X folder"
    }
    
    var body: some View {
        Form {
            Section(header: Text("URL").sectionTitle()) {
                TextField("Link", text: $link).keyboardType(UIKeyboardType.URL)
            }
            
            Section(header: Text("Groups").sectionTitle()) {
                NavigationLink(selectedFolderStringValue) {
                    SelectionList(items: groups, selection: $selectedFolder)
                }
            }
            
            Section(header: Text("Tags").sectionTitle()) {
                NavigationLink(selectedTagsStringValue) {
                    MultipleSelectionList(items: tags, selections: $selectedTags)
                }
            }
        }
        
        .navigationTitle(Text("New URL"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                Button(action: self.addURL) {
                    HStack {
                        Text("Add URL \(Image(systemName: "link.badge.plus"))").font(.system(size: 15))
                    }
                    .padding(.horizontal, 100)
                    .padding(.vertical, 5)
                }
                .foregroundColor(.white)
                .background(Color.purple)
                .clipShape(RoundedRectangle(cornerRadius: 5))
            }
        }
        .onAppear {
            // TODO move all this into view model
            let canc1 = TagStorage.shared.tags.sink { tags in
                self.tags = tags
            }
            let canc2 = GroupStorage.shared.groups.sink { groups in
                self.groups = groups
            }
        }
    }
    
    private func addURL() {
        os_log(.info, "Running AddURL task")
        URLManager.shared.getURLData(url: link) { og in
            os_log(.debug, "Got \(og) from link")
            LinkStorage.shared.add(
                url: link,
                ogTitle: og["og:title"],
                ogDescription: og["og:description"],
                ogImageUrl: og["og:image"],
                note: "",
                starred: false,
                unread: true,
                group: selectedFolder,
                tags: Set<Tag>(selectedTags)
            )
        }
        
        presentationMode.wrappedValue.dismiss()
    }
}

struct AddLinkViewController_Previews: PreviewProvider {
    static var previews: some View {
        AddLinkViewController()
            .preferredColorScheme(.dark)
            .previewInterfaceOrientation(.portrait)
    }
}
