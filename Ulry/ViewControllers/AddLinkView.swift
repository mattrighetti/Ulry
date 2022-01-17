//
//  AddLinkViewController.swift
//  Urly
//
//  Created by Mattia Righetti on 12/25/21.
//

import os
import Combine
import CoreData
import SwiftUI

public struct AddLinkView: View {
    public enum Configuration {
        case edit(Link)
        case new
    }
    
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    var configuration: Configuration
    
    @State var runConfiguration = false
    @State private var presentAlert = false
    @State private var link: String = ""
    @State private var note: String = ""
    @State private var selectedFolder: Group? = nil
    @State private var selectedTags: [Tag] = []
    
    @FetchRequest(entity: Group.entity(), sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)])
    var groups: FetchedResults<Group>
    
    @FetchRequest(entity: Tag.entity(), sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)])
    var tags: FetchedResults<Tag>
    
    var cancellables = Set<AnyCancellable>()
    
    var selectedTagsStringValue: String {
        guard !selectedTags.isEmpty else { return "None" }
        return selectedTags.map { $0.name }.joined(separator: ", ")
    }
    
    var selectedFolderStringValue: String {
        selectedFolder == nil ? "None" : selectedFolder!.name
    }
    
    var navigationBarTitle: String {
        switch configuration {
        case .edit(_):
            return "Update URL"
        case .new:
            return "New URL"
        }
    }
    
    var buttonText: String {
        switch configuration {
        case .edit(_):
            return "Update URL"
        case .new:
            return "Add URL"
        }
    }
    
    var backgroundColor: Color {
        if colorScheme == .dark {
            return Color(hex: "#333333")!.opacity(0.6)
        } else {
            return Color.white
        }
    }
    
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading) {
                    Text("URL")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .padding(.leading, 30)
                    
                    TextField("", text: $link, prompt: Text("Link URL"))
                        .keyboardType(UIKeyboardType.URL)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .padding()
                        .background(backgroundColor)
                        .cornerRadius(10)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal) {
                        HStack {
                            Button(action: {
                                link = ""
                            }, label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 14))
                                    .foregroundColor(.red)
                                    .padding(10)
                                    .background(backgroundColor)
                                    .cornerRadius(10)
                            }).padding(.leading)
                            
                            if UIPasteboard.general.hasStrings {
                                Button(action: {
                                    link += UIPasteboard.general.string ?? ""
                                }, label: {
                                    Image(systemName: "doc.on.clipboard")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                        .padding(10)
                                        .background(backgroundColor)
                                        .cornerRadius(10)
                                })
                            }
                            
                            if !link.contains("https://") {
                                Button(action: {
                                    link = "https://"
                                }, label: {
                                    Text("https://")
                                        .font(.system(size: 14, weight: .regular, design: .monospaced))
                                        .foregroundColor(.white)
                                        .padding(10)
                                        .background(backgroundColor)
                                        .cornerRadius(10)
                                })
                            }
                            
                            if !link.contains("www.") {
                                Button(action: {
                                    link += "www."
                                }, label: {
                                    Text("www.")
                                        .font(.system(size: 14, weight: .regular, design: .monospaced))
                                        .foregroundColor(.white)
                                        .padding(10)
                                        .background(backgroundColor)
                                        .cornerRadius(10)
                                })
                            }
                        }
                    }
                    .padding([.bottom])
                }
                .padding(.top)
                
                VStack(alignment: .leading) {
                    Text("Notes")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .padding(.leading, 30)
                    
                    TextEditor(text: $note)
                        .padding(.horizontal)
                        .frame(height: 100, alignment: .center)
                        .background(backgroundColor)
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .keyboardType(.asciiCapable)
                        .keyboardShortcut(.cancelAction)
                }
                .padding(.bottom, 10)
                
                VStack(alignment: .leading) {
                    Text("Group")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .padding(.leading, 30)
                    NavigationLink(destination: {
                        SelectionList(selection: $selectedFolder)
                    }, label: {
                        HStack {
                            Text(selectedFolderStringValue)
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .foregroundColor(.white)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .padding()
                        .background(backgroundColor)
                        .cornerRadius(10)
                        .padding(.horizontal)
                    })
                }
                .padding(.bottom, 10)
                
                VStack(alignment: .leading) {
                    Text("Tags")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .padding(.leading, 30)
                    NavigationLink(destination: {
                        MultipleSelectionList(selections: $selectedTags)
                    }, label: {
                        HStack {
                            Text(selectedTagsStringValue)
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .foregroundColor(.white)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .padding()
                        .background(backgroundColor)
                        .cornerRadius(10)
                        .padding(.horizontal)
                    })
                }
            }
            .onAppear {
                if !runConfiguration {
                    configure()
                }
            }
            .alert("No URL inserted", isPresented: $presentAlert, actions: {}, message: {
                Text("Please make sure to insert a valid URL")
            })
            
            .navigationTitle(Text(navigationBarTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: onDonePressed) {
                        Text("Done").font(.system(.headline, design: .rounded))
                    }
                }
            }
        }
    }
    
    private func configure() {
        runConfiguration = true
        switch configuration {
        case .edit(let editLink):
            self.link = editLink.url
            self.selectedFolder = editLink.group
            self.selectedTags = Array(editLink.tags!)
        case .new:
            break
        }
    }
    
    private func onDonePressed() {
        switch configuration {
        case .edit(let editedLink):
            editedLink.setValue(link, forKey: "url")
            editedLink.setValue(note, forKey: "note")
            editedLink.setValue(true, forKey: "unread")
            editedLink.setValue(selectedFolder, forKey: "group")
            editedLink.setValue(Set(selectedTags), forKey: "tags")
            
            // TODO this should only run when url is changed
            editedLink.loadMetaData(completion: {
                CoreDataStack.shared.saveContext()
            })
            
        case .new:
            let newLink = Link(context: managedObjectContext)
            newLink.setValue(link, forKey: "url")
            newLink.setValue(note, forKey: "note")
            newLink.setValue(nil, forKey: "imageData")
            newLink.setValue(selectedFolder, forKey: "group")
            newLink.setValue(Set(selectedTags), forKey: "tags")
            
            CoreDataStack.shared.saveContext()
            
            newLink.loadMetaData(completion: {
                CoreDataStack.shared.saveContext()
            })
        }
        
        presentationMode.wrappedValue.dismiss()
    }
}

struct AddLinkViewController_Previews: PreviewProvider {
    static var previews: some View {
        AddLinkView(configuration: .new)
            .preferredColorScheme(.dark)
            .previewInterfaceOrientation(.portrait)
    }
}
