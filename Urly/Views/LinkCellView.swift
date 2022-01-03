//
//  URLCellView.swift
//  Urly
//
//  Created by Mattia Righetti on 12/23/21.
//

import SwiftUI

public enum LinkCellConfiguration {
    // Show only title if present and link
    case minimal
    // Show title and description if present and little image
    case medium
    // Show large image if present with title and description
    case large
}

struct LinkCellView: View {
    var link: Link
    @State var configuration: LinkCellConfiguration = .medium
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yy"
        let date = Date(timeIntervalSince1970: Double(link.createdAt))
        return formatter.string(from: date)
    }
    
    var body: some View {
        Button(action: {
            if let urlString = link.url, let url = URL(string: urlString) {
                UIApplication.shared.open(url)
            }
        }, label: {
            VStack {
                HStack {
                    view()
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
                    Text(dateString)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                    
                    Spacer()
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
    
    @ViewBuilder private func view() -> some View {
        switch configuration {
        case .minimal:
            minimalView()
        case .medium:
            mediumView()
        case .large:
            largeView()
        }
    }
    
    @ViewBuilder
    private func minimalView() -> some View {
        HStack {
            if
                link.ogImageUrl != nil,
                let imgUrl = URL(string: link.ogImageUrl!)
            {
                AsyncImage(
                    url: imgUrl,
                    content: { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.screenWidth / 8, height: UIScreen.screenWidth / 8, alignment: .center)
                            .cornerRadius(10)
                    },
                    placeholder: {
                        ProgressView()
                    }
                )
                .padding(.trailing, 5)
            }
            
            VStack(alignment: .leading) {
                if link.ogTitle != nil {
                    Text(link.ogTitle!)
                        .padding(.vertical, 3)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .lineLimit(2)
                }
                
                if link.ogDescription != nil {
                    Text(link.ogDescription!)
                        .font(.system(size: 12, weight: .regular, design: .default))
                        .lineLimit(2)
                }
            }
        }
    }
    
    @ViewBuilder
    private func mediumView() -> some View {
        HStack {
            if
                link.ogImageUrl != nil,
                let imgUrl = URL(string: link.ogImageUrl!)
            {
                AsyncImage(
                    url: imgUrl,
                    content: { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.screenWidth / 8, height: UIScreen.screenWidth / 8, alignment: .center)
                            .cornerRadius(10)
                    },
                    placeholder: {
                        ProgressView()
                    }
                )
                .padding(.trailing, 5)
            }
            
            VStack(alignment: .leading) {
                if link.ogTitle != nil {
                    Text(link.ogTitle!)
                        .padding(.vertical, 3)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .lineLimit(2)
                } else {
                    Text(link.url!)
                        .padding(.vertical, 3)
                        .font(.system(size: 13, weight: .semibold, design: .default))
                        .lineLimit(2)
                }
                
                if link.ogDescription != nil {
                    Text(link.ogDescription!)
                        .font(.system(size: 12, weight: .regular, design: .default))
                        .lineLimit(2)
                }
            }
        }
    }
    
    @ViewBuilder
    private func largeView() -> some View {
        VStack(alignment: .leading) {
            HStack {
                Spacer()
                if
                    link.ogImageUrl != nil,
                    let imgUrl = URL(string: link.ogImageUrl!)
                {
                    AsyncImage(
                        url: imgUrl,
                        content: { image in
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(height: UIScreen.screenWidth * 3 / 4, alignment: .center)
                                .cornerRadius(10)
                        },
                        placeholder: {
                            ProgressView()
                        }
                    )
                }
                Spacer()
            }
            
            if link.ogTitle != nil {
                Text(link.ogTitle ?? "No title")
                    .padding(.vertical, 3)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .lineLimit(2)
            } else {
                Text(link.url!)
                    .padding(.vertical, 3)
                    .font(.system(size: 17, weight: .bold, design: .monospaced))
                    .lineLimit(2)
            }
            
            if link.ogDescription != nil {
                Text(link.ogDescription ?? "No title")
                    .font(.system(size: 12, weight: .regular, design: .default))
                    .lineLimit(2)
            }
        }
    }
}
