//
//  LinkDetailView.swift
//  Urly
//
//  Created by Mattia Righetti on 1/3/22.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import Links
import SwiftUI

struct LinkDetailView: View {
    var link: Links.Link

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                if
                    let imgData = ImageStorage.shared.getImageData(for: link),
                    let uiImage = UIImage(data: imgData)
                {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: 250)
                        .clipped()
                } else {
                    HStack {
                        Spacer()
                        Text(link.hostname)
                            .font(.system(size: 18.0, weight: .semibold, design: .rounded))
                        Spacer()
                    }
                    .foregroundColor(.white)
                    .frame(height: 160)
                    .background(link.color)
                }

                VStack(alignment: .leading, spacing: 12) {
                    FaviconHostnameView(hostname: link.hostname)

                    LinkMainInfoView()

                    if let note = link.note, !note.isEmpty {
                        Divider()

                        VStack(alignment: .leading) {
                            Text(LocalizedStringKey(stringLiteral: note))
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
        }
    }
    
    @ViewBuilder
    private func LinkMainInfoView() -> some View {
        VStack(alignment: .leading, spacing: 5) {
            if let title = link.ogTitle {
                Text(title)
                    .font(.title3)
            } else {
                Text(link.url)
                    .lineLimit(1)
                    .font(.system(size: 14, weight: .thin, design: .monospaced))
            }
            
            if let description = link.ogDescription {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(5)
            }
        }
    }
}

struct LinkDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let link = Link(url: "https://example.com")
        link.note = """
        This is a particular not about the [link](https://example.com)

        What about some `bold` text?
        """
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
        
        return LinkDetailView(link: link)
            .preferredColorScheme(.dark)
            .previewDevice("iPhone 13 mini")
    }
}
