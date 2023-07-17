//
//  SwiftUIView.swift
//  Ulry
//
//  Created by Mattia Righetti on 10/25/22.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import SwiftUI

struct BackgroundImage: View {
    var systemName: String
    var hex: String
    var height: CGFloat? = 30
    var width: CGFloat? = 30
    
    var body: some View {
        ZStack {
            Color(hex: hex)
            if (systemName.starts(with: "asset:")) {
                Image(systemName.replacingOccurrences(of: "asset:", with: ""))
                    .foregroundColor(.white)
            } else {
                Image(systemName: systemName)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .frame(width: width, height: height)
    }
    
    public static func getHostingViewController(icon systemName: String, hex: String) -> UIView {
        let view = UIHostingController(rootView: BackgroundImage(systemName: systemName, hex: hex)).view
        view!.backgroundColor = .clear
        return view!
    }
}

struct BackgroundImage_Previews: PreviewProvider {
    static var previews: some View {
        BackgroundImage(systemName: "checkmark.seal", hex: "fcde44")
    }
}
