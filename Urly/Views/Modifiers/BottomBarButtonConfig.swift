//
//  BottomBarButtonConfig.swift
//  Urly
//
//  Created by Mattia Righetti on 12/25/21.
//

import SwiftUI

struct ButtonBarButtonConfig: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    var darkColors: (Color, Color)
    var lightColors: (Color, Color)
    
    func body(content: Content) -> some View {
        if self.colorScheme == .dark {
            content
                .symbolRenderingMode(.palette)
                .foregroundStyle(darkColors.0, darkColors.1)
                .font(.system(size: 20))
        } else {
            content
                .symbolRenderingMode(.palette)
                .foregroundStyle(lightColors.0, lightColors.1)
                .font(.system(size: 20))
        }
    }
}

extension View {
    func bottomBarButton(darkColors: (Color, Color), lightColors: (Color, Color)) -> some View {
        modifier(ButtonBarButtonConfig(darkColors: darkColors, lightColors: lightColors))
    }
}
