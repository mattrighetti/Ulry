//
//  URLCellView.swift
//  Urly
//
//  Created by Mattia Righetti on 12/23/21.
//

import SwiftUI

struct LinkCellView: View {
    var link: Link
    var infoPressAction: (() -> Void)? = nil
    
    var body: some View {
        Button(action: {
            if let url = URL(string: link.url) {
                UIApplication.shared.open(url)
            }
        }, label: {
            VStack {
                HStack {
                    LinkDataView()
                    Spacer()
                }
                .padding(.top, 5)
                .padding(.bottom, 3)
                
                HStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                        .padding(3)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                    Text(link.dateString)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                    
                    Spacer()
                    
                    Button(action: infoPressAction ?? {}, label: {
                        Label(title: {
                            Text("info")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                        }, icon: {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 12))
                        })
                    })
                }
                .padding(.bottom, 5)
            }
            .padding(.horizontal)
            .defaultAwareBackgroundColor()
            .cornerRadius(10)
            .padding(.horizontal)
        })
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func LinkDataView() -> some View {
        HStack {
            if
                let imgData = link.imageData,
                let uiImage = UIImage(data: imgData)
            {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: UIScreen.screenWidth / 8, height: UIScreen.screenWidth / 8, alignment: .center)
                    .cornerRadius(10)
                    .padding(.trailing, 5)
                
            } else {
                ZStack {
                    link.color
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        
                    Text(link.hostname.first!.uppercased())
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                }
                .frame(width: UIScreen.screenWidth / 8, height: UIScreen.screenWidth / 8, alignment: .center)
                .padding(.trailing, 5)
                .padding(.top, 10)
            }
            
            VStack(alignment: .leading) {
                if let title = link.ogTitle {
                    Text(title)
                        .padding(.vertical, 3)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .lineLimit(2)
                } else {
                    Text(link.url)
                        .padding(.vertical, 3)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .lineLimit(2)
                }
                
                if let description = link.ogDescription {
                    Text(description)
                        .font(.system(size: 12, weight: .regular, design: .default))
                        .lineLimit(2)
                }
            }
        }
    }
}

struct LinkCellView_Previews: PreviewProvider {
    static var previews: some View {
        let link = Link()
        link.id = UUID()
        link.url = "https://example.com"
        link.colorHex = "#333333"
        link.ogImageUrl = nil
        link.tags = nil
        link.group = nil
        link.unread = true
        link.starred = false
        link.ogImageUrl = nil
        link.ogTitle = nil
        link.ogDescription = nil
        link.note = ""
        link.imageData = nil
        
        return LinkCellView(link: link)
    }
}