//
//  LinkDetailView.swift
//  Urly
//
//  Created by Mattia Righetti on 1/3/22.
//

import SwiftUI

fileprivate class SheetState: ObservableObject {
    @Published var isShowing: Bool = false
    @Published var editLink: Link? = nil {
        didSet {
            isShowing = editLink != nil
        }
    }
}

struct LinkDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var sheet = SheetState()
    
    var link: Link
    
    var imgUrl: URL? {
        guard
            let imgLink = link.ogImageUrl,
            let imgUrl = URL(string: imgLink)
        else {
            return nil
        }
        
        return imgUrl
    }
    
    var title: String {
        link.ogTitle ?? link.url ?? "Rare bug, contact the developer to notify this"
    }
    
    var description: String {
        link.ogDescription ?? ""
    }
    
    var body: some View {
        VStack {
            if imgUrl != nil {
                AsyncImage(
                    url: imgUrl,
                    content: { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(10)
                    },
                    placeholder: {
                        ProgressView()
                            .frame(width: 10, height: 10, alignment: .center)
                    }
                )
                .padding(.horizontal)
                .padding(.top)
            }
            
            HStack {
                if let url = URL(string: link.url!), let hostname = url.host, let faviconUrl = URL(string: "https://" + hostname + "/favicon.ico") {
                    AsyncImage(
                        url: faviconUrl,
                        content: { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 10, height: 10, alignment: .center)
                        },
                        placeholder: {
                            Image(systemName: "link.circle")
                                .font(.system(size: 10))
                        }
                    )
                    
                    Text(hostname)
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(.blue)
                    
                    Spacer()
                }
            }
            .padding(.horizontal)
            .padding(.top, imgUrl != nil ? 0 : 15)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .padding(.bottom, 5)
                
                Text(description)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(.gray.opacity(0.7))
                    .lineLimit(5)
            }
            .padding(.horizontal)
            .padding(.vertical, 3)
            
            if let note = link.note, !note.isEmpty {
                VStack(alignment: .leading) {
                    Text("Note")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .padding(.bottom, 5)
                    
                    Text(note)
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(.gray.opacity(0.7))
                }
                .padding()
                .defaultAwareBackgroundColor()
                .cornerRadius(10)
                .padding()
            }
            
            HStack {
                Button(action: { LinkStorage.shared.toggleStar(link: self.link) }, label: {
                    Spacer()
                    Label(title: { Text("Star").font(.system(size: 13, weight: .regular, design: .rounded)) }, icon: { Image(systemName: self.link.starred ? "star.fill" : "star") })
                        .foregroundColor(.yellow)
                    Spacer()
                })
                Button(action: { LinkStorage.shared.toggleRead(link: self.link) }, label: {
                    Spacer()
                    Label(title: { Text("Read").font(.system(size: 13, weight: .regular, design: .rounded)) }, icon: { Image(systemName: self.link.unread ? "envelope" : "envelope.open") })
                    Spacer()
                })
                Button(action: { sheet.editLink = self.link }, label: {
                    Spacer()
                    Label(title: { Text("Edit").font(.system(size: 13, weight: .regular, design: .rounded)) }, icon: { Image(systemName: "square.and.pencil") })
                    Spacer()
                })
                Button(action: {
                    LinkStorage.shared.delete(link: link)
                    presentationMode.wrappedValue.dismiss()
                }, label: {
                    Spacer()
                    Label(title: { Text("Delete").font(.system(size: 13, weight: .regular, design: .rounded)) }, icon: { Image(systemName: "trash") })
                        .foregroundColor(.red)
                    Spacer()
                })
            }
            .padding()
            
            Spacer()
        }
        .sheet(isPresented: $sheet.isShowing, onDismiss: { sheet.editLink = nil }) {
            NavigationView {
                AddLinkView(configuration: .edit(self.link))
            }
        }
    }
}
