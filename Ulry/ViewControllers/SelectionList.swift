//
//  SelectionList.swift
//  Urly
//
//  Created by Mattia Righetti on 1/2/22.
//

import SwiftUI

struct SelectionList<T: Representable>: View {
    @Environment(\.presentationMode) var presentationMode
    @State var isSheetShown: Bool = false
    @Binding var items: [T]
    @Binding var selection: T?

    var body: some View {
        List {
            Section {
                ForEach(self.items, id: \.self) { item in
                    SelectionRow(title: item.name, isSelected: self.selection == item) {
                        selection = item
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                SelectionRow(title: "None", isSelected: false) {
                    selection = nil
                    presentationMode.wrappedValue.dismiss()
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
            AddCategoryView(mode: .group, onDonePressedAction: {
                isSheetShown.toggle()
            })
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
                    .foregroundColor(.white)
                
                if self.isSelected {
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
        }
    }
}
