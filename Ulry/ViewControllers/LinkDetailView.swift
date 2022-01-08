//
//  LinkDetailView.swift
//  Urly
//
//  Created by Mattia Righetti on 1/3/22.
//

import os
import SwiftUI

fileprivate class SheetState: ObservableObject {
    @Published var isShowing: Bool = false
    @Published var editLink: Link? = nil {
        didSet {
            isShowing = editLink != nil
        }
    }
}

struct FaviconHostnameView: View {
    @State private var favicon: UIImage? = nil
    
    var hostname: String
    
    var body: some View {
        HStack {
            if let favicon = favicon {
                Image(uiImage: favicon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 10, height: 10, alignment: .center)
            } else {
                Image(systemName: "link.circle")
                    .font(.system(size: 10))
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 10, height: 10, alignment: .center)
            }
            
            Text(hostname)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(.blue)
            
            Spacer()
        }
        .padding(.horizontal)
        .onAppear {
            os_log(.info, "fetching favicon for hostname: \(hostname)")
            fetchFavicon(of: hostname) { data in
                DispatchQueue.main.async {
                    os_log(.info, "fetched image")
                    guard let data = data else { return }
                    self.favicon = UIImage(data: data)
                }
            }
        }
    }
    
    private func fetchFavicon(of hostname: String, completion: ((Data?) -> Void)?) {
        if let faviconUrl = URL(string: "https://" + hostname + "/favicon.ico") {
            let task = URLSession.shared.dataTask(with: faviconUrl) { data, _, _ in
                completion?(data)
            }
            task.resume()
        }
    }
}

struct LinkDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var sheet = SheetState()
    @State private var favicon: UIImage? = nil
    
    var link: Link
    
    var hostname: String? {
        guard
            let url = URL(string: link.url)
        else { return nil }
        
        return url.host
    }
    
    var body: some View {
        VStack {
            if
                let imgData = link.imageData,
                let uiImage = UIImage(data: imgData)
            {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 200)
                    .cornerRadius(10)
                    .padding([.horizontal, .top])
                
            } else {
                HStack {
                    Spacer()
                    Text(link.hostname)
                        .shadow(color: .white, radius: 5, x: 0, y: 0)
                    Spacer()
                }
                .foregroundColor(.white)
                .frame(height: 100)
                .background(link.color)
                .cornerRadius(10)
                .padding([.horizontal, .top])
            }
            
            VStack(alignment: .leading) {
                FaviconHostnameView(hostname: link.hostname)
                LinkMainInfoView()
            }
            .padding(.top, 5)
            
            if let note = link.note, !note.isEmpty {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Note")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .padding(.bottom, 5)
                        
                        Text(note)
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundColor(.gray.opacity(0.7))
                    }
                    Spacer()
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
    
    @ViewBuilder
    private func LinkMainInfoView() -> some View {
        VStack(alignment: .leading, spacing: 5) {
            if let title = link.ogTitle {
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
            } else {
                Text(link.url)
                    .lineLimit(1)
                    .font(.system(size: 14, weight: .thin, design: .monospaced))
            }
            
            if let description = link.ogDescription {
                Text(description)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(.gray.opacity(0.7))
                    .lineLimit(5)
            }
        }
        .padding(.horizontal)
    }
}

struct LinkDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.shared.container.viewContext
        let link = Link(context: context)
        link.id = UUID()
        link.url = "https://brennancolberg.com"
        link.colorHex = "#023047"
        link.ogImageUrl = nil
        link.tags = nil
        link.group = nil
        link.unread = true
        link.starred = false
        link.ogImageUrl = nil
        link.ogTitle = "Little title"
        link.ogDescription = "Random description that will for sure surpass"
        link.note = "This is a particular not about the link"
        link.imageData = nil
        
        return LinkDetailView(link: link)
            .preferredColorScheme(.dark)
            .previewDevice("iPhone 13 mini")
    }
}
