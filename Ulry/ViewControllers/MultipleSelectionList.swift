//
//  MultiSelectList.swift
//  Urly
//
//  Created by Mattia Righetti on 1/1/22.
//

import SwiftUI

struct MultipleSelectionList: View {
    @State var items: [Tag] = Database.shared.getAllTags()
    @State var isSheetShown: Bool = false
    @State var selections: [Tag]
    @Binding var selectedTags: [Tag]
    
    var body: some View {
        List {
            Section {
                ForEach(self.items, id: \.self) { item in
                    MultipleSelectionRow(title: item.name, isSelected: self.selections.contains(item)) {
                        if self.selections.contains(item) {
                            self.selections.removeAll(where: { $0 == item })
                            self.selectedTags.removeAll(where: { $0 == item })
                        } else {
                            self.selections.append(item)
                            self.selectedTags.append(item)
                        }
                    }
                }
            }
            
            Section {
                Button(action: {
                    isSheetShown.toggle()
                }) {
                    HStack {
                        Text("Create new")
                        Spacer()
                        Image(systemName: "plus")
                    }
                }
            }
        }.sheet(isPresented: $isSheetShown, onDismiss: {
            withAnimation {
                // TODO horrible code
                items = Database.shared.getAllTags()
            }
        }) {
            AddCategoryViewControlleRepresentable(mode: .tag)
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
