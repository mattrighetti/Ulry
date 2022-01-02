//
//  MultiSelectList.swift
//  Urly
//
//  Created by Mattia Righetti on 1/1/22.
//

import SwiftUI

public protocol Representable: Identifiable, Hashable {
    var name: String { get }
}

struct MultipleSelectionList<T: Representable>: View {
    @State var items: [T] = []
    @Binding var selections: [T]

    var body: some View {
        List {
            ForEach(self.items, id: \.self) { item in
                MultipleSelectionRow(title: item.name, isSelected: self.selections.contains(item)) {
                    if self.selections.contains(item) {
                        self.selections.removeAll(where: { $0 == item })
                    } else {
                        self.selections.append(item)
                    }
                }
            }
        }
    }
}

struct MultipleSelectionRow: View {
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

//struct MultiSelectList_Previews: PreviewProvider {
//    @State private static var selection: [String] = []
//    
//    static var previews: some View {
//        MultipleSelectionList(items: ["Apples", "Oranges", "Bananas", "Pears", "Mangos", "Grapefruit"], selections: $selection)
//            .preferredColorScheme(.dark)
//    }
//}
