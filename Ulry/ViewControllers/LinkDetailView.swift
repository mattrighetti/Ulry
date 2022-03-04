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

struct LinkDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var sheet = SheetState()
    @State private var favicon: UIImage? = nil
    
    var link: Link
    
    var body: some View {
        VStack {
            if
                let imgData = link.imageData,
                let uiImage = UIImage(data: imgData)
            {
                Image(uiImage: uiImage)
                    .resizable()
                    .cornerRadius(10)
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 200)
                    .padding([.horizontal, .top])
                
            } else {
                HStack {
                    Spacer()
                    Text(link.hostname)
                        .shadow(color: .white, radius: 5, x: 0, y: 0)
                    Spacer()
                }
                .foregroundColor(.white)
                .frame(height: 150)
                .background(link.color)
                .cornerRadius(20)
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
            
            Spacer()
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
        let link = Link(url: "https://example.com", note: "This is a particular not about the link")
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
        link.imageData = nil
        
        return LinkDetailView(link: link)
            .preferredColorScheme(.dark)
            .previewDevice("iPhone 13 mini")
    }
}
