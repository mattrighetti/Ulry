//
//  AwareBackgroundColor.swift
//  Urly
//
//  Created by Mattia Righetti on 12/29/21.
//

import SwiftUI

struct AwareBackgroundColor: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    var darkColor: Color
    var lightColor: Color
    
    func body(content: Content) -> some View {
        if self.colorScheme == .dark {
            content
                .background(darkColor)
        } else {
            content
                .background(lightColor)
        }
    }
}

extension View {
    func awareBackgroundColor(darkColor: Color, lightColor: Color) -> some View {
        modifier(AwareBackgroundColor(darkColor: darkColor, lightColor: lightColor))
    }
    
    func defaultAwareBackgroundColor() -> some View {
        modifier(AwareBackgroundColor(darkColor: Color(hex: "#333333")!.opacity(0.1), lightColor: Color(hex: "#333333")!.opacity(0.1)))
    }
}
