//
//  ListLabel.swift
//  Urly
//
//  Created by Mattia Righetti on 12/25/21.
//

import SwiftUI

struct ListLabelImage: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 20))
    }
}

extension View {
    func listLabelImage() -> some View {
        modifier(ListLabelImage())
    }
}
