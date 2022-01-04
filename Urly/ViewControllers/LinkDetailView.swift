//
//  LinkDetailView.swift
//  Urly
//
//  Created by Mattia Righetti on 1/3/22.
//

import SwiftUI

struct LinkDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var link: Link
    
    var body: some View {
        VStack {
            if let imgLink = link.ogImageUrl, let imgUrl = URL(string: imgLink) {
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
                .padding()
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
                            ProgressView()
                                .frame(width: 10, height: 10, alignment: .center)
                        }
                    )
                    
                    Text(hostname)
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(.blue)
                    
                    Spacer()
                }
            }
            .padding(.horizontal)
            
            VStack(alignment: .leading) {
                Text(link.ogTitle ?? "")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .padding(.bottom, 5)
                
                Text(link.ogDescription ?? "")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(.gray.opacity(0.7))
                    .lineLimit(5)
            }
            .padding(.horizontal)
            
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
            
            Spacer()
            
            HStack {
                Button(action: {}, label: {
                    Spacer()
                    Label(title: { Text("Star").font(.system(size: 13, weight: .regular, design: .rounded)) }, icon: { Image(systemName: "star") })
                        .foregroundColor(.yellow)
                    Spacer()
                })
                Button(action: {}, label: {
                    Spacer()
                    Label(title: { Text("Read").font(.system(size: 13, weight: .regular, design: .rounded)) }, icon: { Image(systemName: "shippingbox.circle") })
                    Spacer()
                })
                Button(action: {}, label: {
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
            }.padding()
        }
    }
}
