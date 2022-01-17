//
//  AddFolderView.swift
//  Urly
//
//  Created by Mattia Righetti on 1/2/22.
//

import os
import CoreData
import SwiftUI

public enum PickerMode: Equatable, RawRepresentable {
    case group
    case editGroup(Group)
    case tag
    case editTag(Tag)
    
    public init?(rawValue: String) {
        return nil
    }
    
    public typealias RawValue = String
    
    public var rawValue: RawValue {
        switch self {
        case .group:
            return "group"
        case .editGroup(_):
            return "group"
        case .tag:
            return "tag"
        case .editTag(_):
            return "tag"
        }
    }
}

struct AddCategoryView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) var managedObjectContext
    
    var mode: PickerMode = .group
    
    @State var name: String = ""
    @State var searchIcon: String = ""
    @State var selectedColor: Color = Color.random
    @State var selectedGlyph: String? = SFSymbols.all[Int.random(in: 1..<SFSymbols.all.count)]
    @State private var pickerSelection: Int = 0
    
    var navigationTitle: String {
        switch mode {
        case .group:
            return "New group"
        case .editGroup(_):
            return "Edit group"
        case .tag:
            return "New tag"
        case .editTag(_):
            return "Edit tag"
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    ZStack {
                        selectedColor
                            .clipShape(Circle())
                            .frame(width: 100, height: 100, alignment: .center)

                        if mode == .group {
                            Image(systemName: selectedGlyph!)
                                .font(.system(size: 35))
                                .foregroundColor(.white)
                        }
                    }
                    .shadow(radius: 10)
                    .padding([.top, .horizontal])
                    
                    TextField("", text: $name, prompt: Text("\(mode.rawValue.capitalized) name"))
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(15)
                        .padding()
                }
                .background(Color.gray.opacity(0.2))
                .cornerRadius(15)
                .padding(.top, 5)
                .padding([.horizontal])
                
                ColorPicker("Pick a color", selection: $selectedColor)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(15)
                    .padding(.top, 5)
                    .padding([.horizontal])

                iconPicker()
            }
            .onAppear {
                configure()
            }
            
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: onDonePressed, label: { Text("Done") })
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }, label: { Text("Cancel") })
                }
            }
        }
    }
    
    @ViewBuilder
    private func iconPicker() -> some View {
        if mode == .group {
            ScrollView(.vertical) {
                LazyVGrid(columns: [GridItem](repeating: .init(.flexible()), count: 5)) {
                    ForEach(SFSymbols.all.filter {
                        searchIcon.isEmpty ? true : $0.lowercased().contains(searchIcon.lowercased())
                    }, id: \.self) { symbolName in
                        Button(action: {
                            selectedGlyph = symbolName
                        }, label: {
                            Image(systemName: symbolName)
                                .padding(10)
                                .background(Color.gray.opacity(0.2))
                                .clipShape(Circle())
                                .padding(10)
                        })
                        .foregroundColor(.gray)
                    }
                }
            }
            .overlay(
                VStack {
                    Spacer()
                    TextField("", text: $searchIcon, prompt: Text("Search icon"))
                        .padding()
                        .background(Color(hex: "#222222")!.opacity(0.9))
                        .cornerRadius(15)
                        .padding([.bottom])
                }
            )
            .frame(height: 300)
            .padding(.horizontal)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(15)
            .padding(.top, 5)
            .padding([.horizontal])
        }
    }
    
    private func configure() {
        switch mode {
        case .editGroup(let group):
            self.name = group.name
            self.selectedColor = Color(hex: group.colorHex)!
            self.selectedGlyph = group.iconName
            break
        case .editTag(let tag):
            self.name = tag.name
            self.selectedColor = Color(hex: tag.colorHex)!
            break
        case .group, .tag:
            break
        }
    }
    
    private func onDonePressed() {
        guard !name.isEmpty else { return }
        
        switch mode {
        case .group:
            let group = Group(context: managedObjectContext)
            group.setValue(UUID(), forKey: "id")
            group.setValue(name, forKey: "name")
            group.setValue(selectedColor.toHex!, forKey: "colorHex")
            group.setValue(selectedGlyph, forKey: "iconName")
            
        case .editGroup(let group):
            group.setValue(name, forKey: "name")
            group.setValue(selectedColor.toHex!, forKey: "colorHex")
            group.setValue(selectedGlyph, forKey: "iconName")
            
        case .tag:
            let tag = Tag(context: managedObjectContext)
            tag.setValue(UUID(), forKey: "id")
            tag.setValue(name, forKey: "name")
            tag.setValue(nil, forKey: "description_")
            tag.setValue(selectedColor.toHex!, forKey: "colorHex")
            
        case .editTag(let tag):
            tag.setValue(name, forKey: "name")
            tag.setValue(nil, forKey: "description_")
            tag.setValue(selectedColor.toHex!, forKey: "colorHex")
        }
        
        CoreDataStack.shared.saveContext()
        
        presentationMode.wrappedValue.dismiss()
    }
}

struct GradientPickerView_Previews: PreviewProvider {
    @State private static var color: Color = .black
    @State private static var iconName: String? = "pencil"

    static var previews: some View {
        AddCategoryView(mode: .group)
            .preferredColorScheme(.dark)
    }
}
