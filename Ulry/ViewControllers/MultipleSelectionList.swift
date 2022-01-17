//
//  MultiSelectList.swift
//  Urly
//
//  Created by Mattia Righetti on 1/1/22.
//

import SwiftUI

struct MultipleSelectionList: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    
    @State var isSheetShown: Bool = false
    @Binding var selections: [Tag]
    
    @FetchRequest(entity: Tag.entity(), sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)])
    var items: FetchedResults<Tag>

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
            AddCategoryView(mode: .tag)
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
