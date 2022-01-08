//
//  SectionTitle.swift
//  Urly
//
//  Created by Mattia Righetti on 12/25/21.
//

import SwiftUI

struct SectionTitle: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.system(size: 15, weight: .bold, design: .rounded))
    }
}

extension View {
    func sectionTitle() -> some View {
        modifier(SectionTitle())
    }
}
