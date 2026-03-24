//
//  AddLinkView.swift
//  Ulry
//
//  Created by Mattia Righetti on 3/6/26.
//  Copyright © 2026 Mattia Righetti. All rights reserved.
//

import SwiftUI
import Links
import Account
import LinksMetadata

struct AddLinkView: View {
    enum Configuration: Equatable {
        case edit(Links.Link)
        case new

        static func == (lhs: Configuration, rhs: Configuration) -> Bool {
            switch (lhs, rhs) {
            case (.new, .new):
                return true
            case (.edit(let a), .edit(let b)):
                return a.id == b.id
            default:
                return false
            }
        }
    }

    var account: Account
    var configuration: Configuration = .new

    @Environment(\.dismiss) private var dismiss

    @State private var urlText: String = ""
    @State private var noteText: String = ""
    @State private var selectedGroup: Links.Group? = nil
    @State private var selectedTags: Set<Tag> = []
    @State private var allGroups: [Links.Group] = []
    @State private var allTags: [Tag] = []
    @State private var errorTitle: String? = nil
    @State private var errorMessage: String? = nil
    @State private var showError: Bool = false
    @State private var groupsExpanded: Bool = false
    @State private var tagsExpanded: Bool = false

    @State private var previewTitle: String? = nil
    @State private var previewDescription: String? = nil
    @State private var previewImage: UIImage? = nil
    @State private var previewHostname: String? = nil
    @State private var isLoadingPreview: Bool = false
    @State private var fetchTask: Task<Void, Never>? = nil

    private var isEdit: Bool {
        if case .edit = configuration { return true }
        return false
    }

    private var navigationTitle: String {
        isEdit ? "Edit Link" : "Add Link"
    }

    private var hasPreview: Bool {
        previewTitle != nil || previewDescription != nil || previewImage != nil
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    if isEdit {
                        TextField("Title", text: $urlText)
                            .autocorrectionDisabled(false)
                    } else {
                        TextField("URL", text: $urlText)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .onChange(of: urlText) { newValue in
                                fetchPreviewDebounced(for: newValue)
                            }
                    }
                }

                if !isEdit {
                    if isLoadingPreview {
                        Section {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .padding(.vertical, 20)
                                Spacer()
                            }
                        }
                    } else if hasPreview {
                        Section {
                            LinkPreviewCard(
                                title: previewTitle,
                                description: previewDescription,
                                image: previewImage,
                                hostname: previewHostname
                            )
                            .listRowInsets(EdgeInsets())
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }

                Section("Note") {
                    TextEditor(text: $noteText)
                        .frame(minHeight: 80)
                }

                Section {
                    DisclosureGroup(isExpanded: $groupsExpanded) {
                        if allGroups.isEmpty {
                            Text("No groups yet")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(allGroups, id: \.id) { group in
                                Button {
                                    if selectedGroup?.id == group.id {
                                        selectedGroup = nil
                                    } else {
                                        selectedGroup = group
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: group.iconName)
                                            .foregroundColor(Color(hex: group.colorHex) ?? .blue)
                                            .frame(width: 24)
                                        Text(group.name)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        if selectedGroup?.id == group.id {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text("Group")
                            Spacer()
                            Text(selectedGroup?.name ?? "None")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section {
                    DisclosureGroup(isExpanded: $tagsExpanded) {
                        if allTags.isEmpty {
                            Text("No tags yet")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(allTags, id: \.id) { tag in
                                Button {
                                    if selectedTags.contains(tag) {
                                        selectedTags.remove(tag)
                                    } else {
                                        selectedTags.insert(tag)
                                    }
                                } label: {
                                    HStack {
                                        Circle()
                                            .fill(Color(hex: tag.colorHex) ?? .blue)
                                            .frame(width: 10, height: 10)
                                        Text(tag.name)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        if selectedTags.contains(tag) {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text("Tags")
                            Spacer()
                            Text(selectedTagsLabel)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: hasPreview)
            .animation(.easeInOut(duration: 0.2), value: isLoadingPreview)
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
            .onAppear {
                loadData()
            }
            .onReceive(NotificationCenter.default.publisher(for: .UserDidAddGroup)) { _ in
                allGroups = (try? account.fetchAllGroups()) ?? []
            }
            .onReceive(NotificationCenter.default.publisher(for: .UserDidAddTag)) { _ in
                allTags = (try? account.fetchAllTags()) ?? []
            }
        }
        .navigationViewStyle(.stack)
    }

    private var selectedTagsLabel: String {
        if selectedTags.isEmpty { return "None" }
        return selectedTags.map { $0.name }.joined(separator: ", ")
    }

    private func loadData() {
        allGroups = (try? account.fetchAllGroups()) ?? []
        allTags = (try? account.fetchAllTags()) ?? []

        if case .edit(let link) = configuration {
            urlText = link.ogTitle ?? ""
            noteText = link.note ?? ""
            selectedGroup = link.group
            if let tags = link.tags {
                selectedTags = tags
            }
        } else {
            if UIPasteboard.general.hasURLs {
                if let url = UIPasteboard.general.url {
                    urlText = url.absoluteString
                }
            } else if UIPasteboard.general.hasStrings {
                if let text = UIPasteboard.general.string {
                    urlText = text
                }
            }
        }
    }

    private func isValidURL(_ string: String) -> Bool {
        guard string.hasPrefix("https://") || string.hasPrefix("http://"),
              URL(string: string) != nil else {
            return false
        }
        return true
    }

    private func fetchPreviewDebounced(for urlString: String) {
        fetchTask?.cancel()

        guard isValidURL(urlString) else {
            previewTitle = nil
            previewDescription = nil
            previewImage = nil
            previewHostname = nil
            isLoadingPreview = false
            return
        }

        fetchTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }

            await MainActor.run { isLoadingPreview = true }

            let tempLink = Links.Link(url: urlString)
            let processed = await account.dataQueue.process(tempLink)

            guard !Task.isCancelled else { return }

            var image: UIImage? = nil
            if let imageData = await account.dataQueue.imageWorker(processed) {
                image = UIImage(data: imageData)
            }

            guard !Task.isCancelled else { return }

            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.3)) {
                    previewTitle = processed.ogTitle
                    previewDescription = processed.ogDescription
                    previewImage = image
                    previewHostname = processed.hostname
                    isLoadingPreview = false
                }
            }
        }
    }

    private func save() {
        let trimmed = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        urlText = trimmed

        guard !trimmed.isEmpty else {
            showValidationError(title: "Invalid input", message: "Please enter valid text to continue")
            return
        }

        if case .edit(let link) = configuration {
            link.group = selectedGroup
            link.tags = selectedTags
            link.note = noteText.isEmpty ? nil : noteText
            link.ogTitle = trimmed

            Task {
                await account.update(link: link)
            }
        }

        if case .new = configuration {
            guard trimmed.hasPrefix("https://") || trimmed.hasPrefix("http://") else {
                showValidationError(title: "Invalid URL", message: "Links must either start with http or https")
                return
            }

            guard URL(string: trimmed) != nil else {
                showValidationError(title: "Invalid URL", message: "Please enter a valid URL to continue")
                return
            }

            guard (try? !account.existsLink(with: trimmed)) ?? true else {
                showValidationError(title: "Duplicate link", message: "A link '\(trimmed)' has already been saved previously")
                return
            }

            let link = Links.Link(url: trimmed)
            link.group = selectedGroup
            link.tags = selectedTags
            link.note = noteText.isEmpty ? nil : noteText

            Task {
                await account.insert(link: link)
                await AppReviewManager().registerReviewWorthyAction()
            }
        }

        dismiss()
    }

    private func showValidationError(title: String, message: String) {
        errorTitle = title
        errorMessage = message
        showError = true
    }
}

// MARK: - Link Preview Card

private struct LinkPreviewCard: View {
    var title: String?
    var description: String?
    var image: UIImage?
    var hostname: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxHeight: 180)
                    .clipped()
            }

            VStack(alignment: .leading, spacing: 6) {
                if let hostname = hostname {
                    Text(hostname.uppercased())
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }

                if let title = title {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                }

                if let description = description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
            }
            .padding(12)
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground))
    }
}
