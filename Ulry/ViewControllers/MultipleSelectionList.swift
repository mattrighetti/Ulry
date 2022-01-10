//
//  MultiSelectList.swift
//  Urly
//
//  Created by Mattia Righetti on 1/1/22.
//

import SwiftUI

struct MultipleSelectionList<T: Representable>: View {
    @State var isSheetShown: Bool = false
    @Binding var items: [T]
    @Binding var selections: [T]

    var body: some View {
        List {
            Section {
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
            
            Section {
                Button(action: { isSheetShown.toggle() }) {
                    HStack {
                        Text("Create new")
                        Spacer()
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $isSheetShown) {
            AddCategoryView(mode: .tag, onDonePressedAction: { isSheetShown.toggle() })
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
                Text(self.title).foregroundColor(.white)
                
                if self.isSelected {
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
        }
    }
}
