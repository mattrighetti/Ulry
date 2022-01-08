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
                    mediumView()
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
                    
                    Button(action: infoPressAction ?? {}, label: {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 12))
                        Text("info")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
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
            } else if let url = URL(string: link.url!), let hostFirstLetter = url.host?.first?.uppercased() {
                ZStack {
                    Color.random
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        
                    Text(hostFirstLetter)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                }
                .frame(width: UIScreen.screenWidth / 8, height: UIScreen.screenWidth / 8, alignment: .center)
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
}
