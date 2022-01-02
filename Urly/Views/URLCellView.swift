//
//  URLCellView.swift
//  Urly
//
//  Created by Mattia Righetti on 12/23/21.
//

import SwiftUI
import LinkPresentation

struct URLCellView: View {
    let url: URL
    
    @StateObject private var metaData = MetaData()
    
    @State var metas: [String:String]? = nil
    @State var imageUrl: URL? = nil
    @State var title: String? = nil
    
    var body: some View {
        GeometryReader { proxy in
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        Spacer()
                        AsyncImage(
                            url: URL(string: metaData.og["og:image"] ?? "none")!,
                            content: { image in
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: proxy.size.width - 5)
                                    .cornerRadius(10)
                            },
                            placeholder: {
                                ProgressView()
                            }
                        )
                        Spacer()
                    }
                    Text(metaData.og["og:title"] ?? "No title")
                        .padding(.vertical, 3)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .lineLimit(2)
                    Text(metaData.og["og:description"] ?? "No title")
                        .font(.system(size: 12, weight: .regular, design: .default))
                        .lineLimit(2)
                }
                .padding()
                
                Spacer()
            }
            .defaultAwareBackgroundColor()
            .cornerRadius(10)
            .onAppear {
                metaData.fetchOg(urlString: url.absoluteString)
            }
        }
    }
}

struct URLCellView_Previews: PreviewProvider {
    static var previews: some View {
        URLCellView(url: URL(string: "https://example.com")!)
            .preferredColorScheme(.dark)
        URLCellView(url: URL(string: "https://github.com/misyobun/MetaRod")!)
            .preferredColorScheme(.dark)
    }
}
