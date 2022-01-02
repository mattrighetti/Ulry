//
//  AddFolderView.swift
//  Urly
//
//  Created by Mattia Righetti on 1/2/22.
//

import os
import SwiftUI

public enum PickerMode: String {
    case folder
    case tag
}

struct IconColorPickerView: View {
    var mode: PickerMode = .folder
    
    @Environment(\.presentationMode) var presentationMode
    @State var name: String = ""
    @State var selectedColor: Color = Color(hex: "#333333")!
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

                        if mode == .folder {
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
            
            .navigationTitle(Text("New \(self.mode.rawValue)"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: save, label: { Text("Done") })
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }, label: { Text("Canel") })
                }
            }
        }
    }
    
    @ViewBuilder
    private func iconPicker() -> some View {
        if mode == .folder {
            ScrollView(.vertical) {
                LazyVGrid(columns: [GridItem](repeating: .init(.flexible()), count: 4)) {
                    ForEach(SFSymbols.all, id: \.self) { symbolName in
                        Button(action: {
                            selectedGlyph = symbolName
                        }, label: {
                            Image(systemName: symbolName)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .clipShape(Circle())
                                .padding()
                        })
                        .foregroundColor(.gray)
                    }
                }
            }
            .frame(height: 300)
            .padding(.horizontal)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(15)
            .padding(.top, 5)
            .padding([.horizontal])
        }
    }
    
    private func save() {
        guard !name.isEmpty else { return }
        
        if mode == .folder {
            GroupStorage.shared.add(name: name, color: selectedColor.toHex!, icon: selectedGlyph!)
        } else {
            TagStorage.shared.add(name: name, description: "", color: selectedColor.toHex!)
        }
        
        presentationMode.wrappedValue.dismiss()
    }
}

struct GradientPickerView_Previews: PreviewProvider {
    @State private static var color: Color = .black
    @State private static var iconName: String? = "pencil"

    static var previews: some View {
        IconColorPickerView(mode: .folder)
            .preferredColorScheme(.dark)
    }
}
