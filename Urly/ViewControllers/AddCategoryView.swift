//
//  AddFolderView.swift
//  Urly
//
//  Created by Mattia Righetti on 1/2/22.
//

import os
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
    
    var mode: PickerMode = .group
    
    var onDonePressedAction: (() -> Void)?
    @State var name: String = ""
    @State var searchIcon: String = ""
    @State var selectedColor: Color = Color.random
    @State var selectedGlyph: String? = SFSymbols.all[Int.random(in: 1..<SFSymbols.all.count)]
    @State private var pickerSelection: Int = 0

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
            
            .navigationTitle(Text("New \(self.mode.rawValue)"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: onDonePressed, label: { Text("Done") })
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        if onDonePressedAction != nil {
                            onDonePressedAction!()
                        } else {
                            presentationMode.wrappedValue.dismiss()
                        }
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
            GroupStorage.shared.add(name: name, color: selectedColor.toHex!, icon: selectedGlyph!)
        case .editGroup(let group):
            GroupStorage.shared.update(group: group, name: name, color: selectedColor.toHex!, icon: selectedGlyph!)
        case .tag:
            TagStorage.shared.add(name: name, description: "", color: selectedColor.toHex!)
        case .editTag(let tag):
            TagStorage.shared.update(tag: tag, name: name, description: "", color: selectedColor.toHex!)
        }
        
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
