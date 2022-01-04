//
//  AddLinkViewController.swift
//  Urly
//
//  Created by Mattia Righetti on 12/25/21.
//

import os
import Combine
import SwiftUI

public class LinkManagerViewModel: ObservableObject {
    @Published var tags = [Tag]()
    @Published var groups = [Group]()
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        TagStorage.shared.tags.sink { tags in
            self.tags = tags
        }
        .store(in: &cancellables)
        
        GroupStorage.shared.groups.sink { groups in
            self.groups = groups
        }
        .store(in: &cancellables)
    }
}

struct AddLinkViewController: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = LinkManagerViewModel()
    @State private var presentAlert = false
    @State private var link: String = ""
    @State private var selectedFolder: Group? = nil
    @State private var selectedTags: [Tag] = []
    @State private var tags: [Tag] = []
    @State private var groups: [Group] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    private var selectedTagsStringValue: String {
        guard !selectedTags.isEmpty else { return "None" }
        return selectedTags.map { $0.name }.joined(separator: ", ")
    }
    
    private var selectedFolderStringValue: String {
        selectedFolder == nil ? "None" : selectedFolder!.name
    }
    
    var body: some View {
        VStack {
            Form {
                Section(header: Text("URL").sectionTitle()) {
                    TextField("Link", text: $link).keyboardType(UIKeyboardType.URL)
                }
                
                Section(header: Text("Groups").sectionTitle()) {
                    NavigationLink(selectedFolderStringValue) {
                        SelectionList(items: viewModel.groups, selection: $selectedFolder)
                    }
                }
                
                Section(header: Text("Tags").sectionTitle()) {
                    NavigationLink(selectedTagsStringValue) {
                        MultipleSelectionList(items: viewModel.tags, selections: $selectedTags)
                    }
                }
            }
            
            Button(action: self.addURL) {
                Text("Add URL \(Image(systemName: "link.badge.plus"))")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .tint(.blue)
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.automatic)
            .controlSize(.large)
        }
        .alert("No URL inserted", isPresented: $presentAlert, actions: {}, message: {
            Text("Please make sure to insert a valid URL")
        })
        
        .navigationTitle(Text("New URL"))
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func addURL() {
        link = link.trimmingCharacters(in: .whitespacesAndNewlines)
        guard
            !link.isEmpty,
            URL(string: link) != nil
        else {
            presentAlert.toggle()
            return
        }
        
        URLManager.shared.getURLData(url: link) { og in
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
