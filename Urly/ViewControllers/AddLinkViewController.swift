//
//  AddLinkViewController.swift
//  Urly
//
//  Created by Mattia Righetti on 12/25/21.
//

import os
import Combine
import SwiftUI

class LinkManagerViewModel: ObservableObject {
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

public struct AddLinkViewController: View {
    public enum AddLinkConfiguration {
        case edit(Link)
        case new
    }
    
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = LinkManagerViewModel()
    
    var configuration: AddLinkConfiguration
    
    @State private var presentAlert = false
    @State private var link: String = ""
    @State private var selectedFolder: Group? = nil
    @State private var selectedTags: [Tag] = []
    @State private var tags: [Tag] = []
    @State private var groups: [Group] = []
    
    var cancellables = Set<AnyCancellable>()
    
    var selectedTagsStringValue: String {
        guard !selectedTags.isEmpty else { return "None" }
        return selectedTags.map { $0.name }.joined(separator: ", ")
    }
    
    var selectedFolderStringValue: String {
        selectedFolder == nil ? "None" : selectedFolder!.name
    }
    
    var buttonText: String {
        switch configuration {
        case .edit(_):
            return "Update URL"
        case .new:
            return "Add URL"
        }
    }
    
    public var body: some View {
        VStack {
            List {
                Section(header: Text("URL").sectionTitle()) {
                    TextField("", text: $link, prompt: Text("Link URL"))
                        .keyboardType(UIKeyboardType.URL)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
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
        }
        .onAppear {
            configure()
        }
        .alert("No URL inserted", isPresented: $presentAlert, actions: {}, message: {
            Text("Please make sure to insert a valid URL")
        })
        
        .navigationTitle(Text("New URL"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: onDonePressed) {
                    Text("Done").font(.system(.headline, design: .rounded))
                }
            }
        }
    }
    
    private func configure() {
        switch configuration {
        case .edit(let editLink):
            self.link = editLink.url!
            self.selectedFolder = editLink.group
            self.selectedTags = editLink.tags!
        case .new:
            break
        }
    }
    
    private func onDonePressed() {
        switch configuration {
        case .edit(let editLink):
            fetchData(completion: { og in
                LinkStorage.shared.update(
                    link: editLink,
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
            })
        case .new:
            fetchData(completion: { og in
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
            })
        }
    }
    
    private func fetchData(completion: @escaping (([String:String]) -> Void)) {
        link = link.trimmingCharacters(in: .whitespacesAndNewlines)
        guard
            !link.isEmpty,
            URL(string: link) != nil
        else {
            presentAlert.toggle()
            return
        }
        
        URLManager.shared.getURLData(url: link) { og in
            completion(og)
        }
        
        presentationMode.wrappedValue.dismiss()
    }
}

struct AddLinkViewController_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AddLinkViewController(configuration: .new)
                .preferredColorScheme(.dark)
                .previewInterfaceOrientation(.portrait)
        }
    }
}
