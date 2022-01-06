//
//  LinkCounterText.swift
//  Urly
//
//  Created by Mattia Righetti on 1/5/22.
//

import SwiftUI

struct LinkCounterText: View {
    var count: Int?
    
    var numText: String? {
        if let count = count {
            if count == 0 {
                return nil
            } else {
                return String(count)
            }
        } else {
            return nil
        }
    }
    
    var body: some View {
        if let numText = numText {
            Text(numText)
                .foregroundColor(.white)
                .font(Font.system(size: 10, weight: .semibold, design: .rounded))
                .padding(5)
                .background(.gray.opacity(0.4))
                .clipShape(Capsule())
        } else {
            EmptyView()
        }
    }
}
