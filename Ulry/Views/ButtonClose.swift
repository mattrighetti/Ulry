//
//  ButtonClose.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/19/22.
//

import SwiftUI

struct ButtonClose: View {
    var action: (() -> Void)? = nil
    
    var body: some View {
        Button(action: { action?() }, label: {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 25))
                .modifier(ColorModifier())
        })
    }
    
    struct ColorModifier: ViewModifier {
        @Environment(\.colorScheme) var colorScheme
        
        func body(content: Content) -> some View {
            if colorScheme == .dark {
                content
                    .foregroundStyle(
                        Color(hex: "#A1A1A8")!,
                        Color(hex: "#323236")!
                    )
            } else {
                content
                    .foregroundStyle(
                        Color(hex: "#7F7F84")!,
                        Color(hex: "#E3E3E8")!
                    )
            }
        }
    }
}

struct ButtonClose_Previews: PreviewProvider {
    static var previews: some View {
        ButtonClose()
    }
}
