//
//  FaviconHostnameView.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/9/22.
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
        .onAppear {
            fetchFavicon(of: hostname) { data in
                DispatchQueue.main.async {
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

struct FaviconHostnameView_Previews: PreviewProvider {
    static var previews: some View {
        FaviconHostnameView(hostname: "facebook.com")
    }
}
