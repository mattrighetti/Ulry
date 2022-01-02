//
//  SelectionList.swift
//  Urly
//
//  Created by Mattia Righetti on 1/2/22.
//

import SwiftUI

struct SelectionList<T: Representable>: View {
    @State var items: [T] = []
    @Binding var selection: T?

    var body: some View {
        List {
            ForEach(self.items, id: \.self) { item in
                SelectionRow(title: item.name, isSelected: self.selection == item) {
                    self.selection = item
                }
            }
            
            SelectionRow(title: "None", isSelected: false) {
                self.selection = nil
            }
        }
    }
}

struct SelectionRow: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: self.action) {
            HStack {
                Text(self.title)
                if self.isSelected {
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
        }
    }
}
