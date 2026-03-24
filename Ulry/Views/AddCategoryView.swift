//
//  AddCategoryView.swift
//  Ulry
//
//  Created by Mattia Righetti on 3/6/26.
//  Copyright © 2026 Mattia Righetti. All rights reserved.
//

import SwiftUI
import Links
import Account

struct AddCategoryView: View {
    enum Mode: Equatable {
        case group
        case editGroup(Links.Group)
        case tag
        case editTag(Links.Tag)
    }

    var account: Account
    var configuration: Mode = .tag

    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var selectedColor: Color = Color(UIColor.random)
    @State private var selectedIcon: String = SFSymbols.all[Int.random(in: 1..<SFSymbols.all.count)]
    @State private var showColorPicker: Bool = false
    @State private var showIconPicker: Bool = false
    @State private var errorTitle: String? = nil
    @State private var errorMessage: String? = nil
    @State private var showError: Bool = false

    private var isGroup: Bool {
        switch configuration {
        case .group, .editGroup: return true
        case .tag, .editTag: return false
        }
    }

    private var navigationTitle: String {
        switch configuration {
        case .group: return "New Group"
        case .editGroup: return "Edit Group"
        case .tag: return "New Tag"
        case .editTag: return "Edit Tag"
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(selectedColor)
                                .frame(width: 80, height: 80)
                                .shadow(color: selectedColor.opacity(0.4), radius: 8, y: 4)

                            if isGroup {
                                Image(systemName: selectedIcon)
                                    .font(.system(size: 30, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                    .padding(.vertical, 8)
                }

                Section {
                    TextField("Name", text: $name)
                        .autocorrectionDisabled()
                }

                Section {
                    ColorPicker("Color", selection: $selectedColor, supportsOpacity: false)

                    if isGroup {
                        Button {
                            showIconPicker = true
                        } label: {
                            HStack {
                                Text("Icon")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: selectedIcon)
                                    .foregroundColor(.secondary)
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary.opacity(0.5))
                            }
                        }
                    }
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                }
            }
            .alert(errorTitle ?? "Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
            .sheet(isPresented: $showIconPicker) {
                IconPickerView(selectedIcon: $selectedIcon, isPresented: $showIconPicker)
            }
            .onAppear {
                configure()
            }
        }
        .navigationViewStyle(.stack)
    }

    private func configure() {
        switch configuration {
        case .editGroup(let group):
            name = group.name
            selectedColor = Color(UIColor(hex: group.colorHex) ?? .blue)
            selectedIcon = group.iconName
        case .editTag(let tag):
            name = tag.name
            selectedColor = Color(UIColor(hex: tag.colorHex) ?? .blue)
        default:
            break
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        name = trimmed

        guard !trimmed.isEmpty else {
            showValidationError(title: "Field is empty", message: "Fill out all the fields to continue")
            return
        }

        let colorHex = UIColor(selectedColor).toHex ?? "#000000"

        switch configuration {
        case .tag:
            if (try? account.existsTag(with: trimmed)) == true {
                showValidationError(title: "Duplicate tag", message: "A tag with the name \(trimmed) already exists")
                return
            }
            let tag = Tag(colorHex: colorHex, name: trimmed)
            Task { await account.insert(tag: tag) }

        case .editTag(let tag):
            if tag.name != trimmed && ((try? account.existsTag(with: trimmed)) == true) {
                showValidationError(title: "Duplicate tag", message: "A tag with the name \(trimmed) already exists")
                return
            }
            tag.name = trimmed
            tag.colorHex = colorHex
            Task { await account.update(tag: tag) }

        case .group:
            if (try? account.existsGroup(with: trimmed)) == true {
                showValidationError(title: "Duplicate group", message: "A group with the name \(trimmed) already exists")
                return
            }
            let group = Group(colorHex: colorHex, iconName: selectedIcon, name: trimmed, links: nil)
            Task { await account.insert(group: group) }

        case .editGroup(let group):
            if group.name != trimmed && ((try? account.existsGroup(with: trimmed)) == true) {
                showValidationError(title: "Duplicate group", message: "A group with the name \(trimmed) already exists")
                return
            }
            group.name = trimmed
            group.colorHex = colorHex
            group.iconName = selectedIcon
            Task { await account.update(group: group) }
        }

        dismiss()
    }

    private func showValidationError(title: String, message: String) {
        errorTitle = title
        errorMessage = message
        showError = true
    }
}

// MARK: - Icon Picker

private struct IconPickerView: View {
    @Binding var selectedIcon: String
    @Binding var isPresented: Bool

    @State private var searchText: String = ""

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 6)

    private var filteredSymbols: [String] {
        if searchText.isEmpty {
            return SFSymbols.all
        }
        return SFSymbols.all.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(filteredSymbols, id: \.self) { symbol in
                        Button {
                            selectedIcon = symbol
                            isPresented = false
                        } label: {
                            Image(systemName: symbol)
                                .font(.system(size: 18))
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(
                                    selectedIcon == symbol
                                        ? Color.accentColor.opacity(0.15)
                                        : Color(.systemGray6)
                                )
                                .foregroundColor(selectedIcon == symbol ? .accentColor : .secondary)
                                .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle("Select Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search icons")
        }
        .navigationViewStyle(.stack)
    }
}
