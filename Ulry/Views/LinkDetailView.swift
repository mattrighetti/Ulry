//
//  LinkDetailView.swift
//  Urly
//
//  Created by Mattia Righetti on 1/3/22.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import Links
import SwiftUI

fileprivate var maxWidth: CGFloat = {
    if UIDevice.current.userInterfaceIdiom == .pad {
        return 600.0
    } else {
        return UIScreen.screenWidth - 30
    }
}()

fileprivate var maxHeight: CGFloat = {
    if UIDevice.current.userInterfaceIdiom == .pad {
        return 800.0
    } else {
        return UIScreen.screenHeight * 2 / 3
    }
}()

fileprivate var imageMaxHeight: CGFloat = {
    if UIDevice.current.userInterfaceIdiom == .pad {
        return 400.0
    } else {
        return 300.0
    }
}()

struct LinkDetailView: View {
    @Environment(\.dismiss) var dismiss
    @State private var favicon: UIImage? = nil
    
    var link: Links.Link

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack {
                VStack {
                    if
                        let imgData = ImageStorage.shared.getImageData(for: link),
                        let uiImage = UIImage(data: imgData)
                    {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: imageMaxHeight)

                    } else {
                        HStack {
                            Spacer()
                            Text(link.hostname)
                                .font(.system(size: 18.0, weight: .semibold, design: .rounded))
                            Spacer()
                        }
                        .foregroundColor(.white)
                        .frame(height: 200)
                        .background(link.color)

                    }
                }.overlay(alignment: .topTrailing) {
                    Button(action: {
                        dismiss()
                    }, label: {
                        Label("", systemImage: "xmark.circle.fill")
                            .font(.system(size: 25))
                            .foregroundColor(Color.gray.opacity(0.5))
                    })
                    .padding(.top, 15)
                    .padding(.leading, 25)
                    .padding(.trailing, 5)
                }


                VStack(alignment: .leading) {
                    FaviconHostnameView(hostname: link.hostname)
                    LinkMainInfoView()
                }
                .padding(.top, 15)


                if let note = link.note, !note.isEmpty {
                    Divider()
                        .padding(.vertical, 20)

                    HStack {
                        VStack(alignment: .leading) {
                            Text(LocalizedStringKey(stringLiteral: note))
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal, 10)
                }

                Spacer()
            }
            .padding(.bottom, 40)
            .cornerRadius(35)
        }
        .background(UITraitCollection.current.userInterfaceStyle == .dark ? Color(uiColor: UIColor(named: "bg-color")!) : Color.white)
        .cornerRadius(35)
        .frame(maxWidth: maxWidth, maxHeight: maxHeight)
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
        .padding(.horizontal)
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
