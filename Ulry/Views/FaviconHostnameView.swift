//
//  FaviconHostnameView.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/9/22.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import SwiftUI

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
        .task {
            guard let data = await fetchFavicon(of: hostname) else { return }
            self.favicon = UIImage(data: data)
        }
    }

    private func fetchFavicon(of hostname: String) async -> Data? {
        guard let faviconUrl = URL(string: "https://" + hostname + "/favicon.ico") else { return nil }
        do {
            let (data, response) = try await URLSession.shared.data(from: faviconUrl)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            return data
        } catch {
            return nil
        }
    }
}

struct FaviconHostnameView_Previews: PreviewProvider {
    static var previews: some View {
        FaviconHostnameView(hostname: "facebook.com")
    }
}
