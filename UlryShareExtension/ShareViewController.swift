//
//  ShareViewController.swift
//  UlryShareExtension
//
//  Created by Mattia Righetti on 29/03/2026.
//  Copyright © 2026 Mattia Righetti. All rights reserved.
//

import UIKit
import SwiftUI
import LinksMetadata
import UniformTypeIdentifiers

final class ShareViewController: UIHostingController<ShareCardView> {

    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: ShareCardView(extensionContext: nil))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        rootView = ShareCardView(extensionContext: extensionContext)
    }
}

// MARK: - Extension Queue Manager

private class ExtensionQueueManager {
    private static let suite = "group.com.mattrighetti.Ulry"
    private static let key = "pendingLinks"

    private var defaults: UserDefaults? {
        UserDefaults(suiteName: Self.suite)
    }

    var canSaveMoreLinks: Bool {
        pendingLinks.count < 15
    }

    var pendingLinks: [ExtensionsAddLinkRequests] {
        guard
            let data = defaults?.data(forKey: Self.key),
            let links = try? JSONDecoder().decode([ExtensionsAddLinkRequests].self, from: data)
        else { return [] }
        return links
    }

    func add(_ urlString: String, note: String?, tagIds: [String]? = nil, groupId: String? = nil) {
        var links = pendingLinks
        links.append(ExtensionsAddLinkRequests(url: urlString, note: note, tagIds: tagIds, groupId: groupId))
        if let data = try? JSONEncoder().encode(links) {
            defaults?.set(data, forKey: Self.key)
        }
    }

    func clearAll() {
        defaults?.removeObject(forKey: Self.key)
    }
}

// MARK: - Simple Models (to avoid Links framework linking issues)

struct SimpleTag: Decodable {
    let id: String
    let name: String
    let colorHex: String
}

struct SimpleGroup: Decodable {
    let id: String
    let name: String
    let colorHex: String
    let iconName: String
}

// MARK: - Card

private enum LoadState {
    case loading
    case ready(url: URL, hostname: String, title: String, description: String?, imageUrl: String?)
    case limitReached
    case failed
}

struct ShareCardView: View {
    let extensionContext: NSExtensionContext?

    @State private var loadState: LoadState = .loading
    @State private var note = ""
    @State private var selectedTagIds = Set<String>()
    @State private var selectedGroupId: String?
    @State private var availableTags: [SimpleTag] = []
    @State private var availableGroups: [SimpleGroup] = []

    private let requestsManager = ExtensionQueueManager()

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    content
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(uiColor: .systemBackground))
            .cornerRadius(20, corners: [.topLeft, .topRight])
        }
        .task {
            await loadContent()
            loadAvailableTagsAndGroups()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch loadState {
        case .loading:
            HStack(spacing: 12) {
                ProgressView()
                Text("Fetching link…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 24)

        case let .ready(_, hostname, title, description, imageUrl):
            VStack(alignment: .leading, spacing: 12) {
                // Image
                if let imageUrl = imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 120)
                                .clipped()
                        case .empty:
                            ProgressView()
                                .frame(height: 120)
                        case .failure:
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 80)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .cornerRadius(8)
                }

                // Hostname + Title
                VStack(alignment: .leading, spacing: 4) {
                    Text(hostname)
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Text(title)
                        .font(.headline)
                        .lineLimit(2)
                }

                // Description
                if let description = description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Divider()
                    .padding(.vertical, 8)

                // Note field
                TextField("Add a note (optional)", text: $note)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .background(Color(uiColor: .tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .submitLabel(.done)

                // Tags
                if !availableTags.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tags")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(availableTags, id: \.id) { tag in
                                    TagPill(
                                        tag: tag,
                                        isSelected: selectedTagIds.contains(tag.id)
                                    ) {
                                        if selectedTagIds.contains(tag.id) {
                                            selectedTagIds.remove(tag.id)
                                        } else {
                                            selectedTagIds.insert(tag.id)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Groups
                if !availableGroups.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Group")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)

                        Menu {
                            Button("None") {
                                selectedGroupId = nil
                            }
                            ForEach(availableGroups, id: \.id) { group in
                                Button(group.name) {
                                    selectedGroupId = group.id
                                }
                            }
                        } label: {
                            HStack {
                                Text(availableGroups.first { $0.id == selectedGroupId }?.name ?? "None")
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color(uiColor: .tertiarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }

                // Save button
                Button(action: save) {
                    Text("Save to Ulry")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.top, 12)
            }

        case .limitReached:
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.black, .yellow)
                    .font(.system(size: 44))
                    .padding(.vertical, 8)

                Text("Link limit reached")
                    .font(.headline)

                Text("Open Ulry to process your saved links before adding more.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button("Close") {
                    extensionContext?.completeRequest(returningItems: nil)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
            }
            .padding(.vertical, 8)

        case .failed:
            VStack(spacing: 12) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 44))
                    .padding(.vertical, 8)

                Text("Couldn't load link")
                    .font(.headline)

                Button("Dismiss") {
                    extensionContext?.cancelRequest(withError: NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Data loading

    private func loadContent() async {
        guard requestsManager.canSaveMoreLinks else {
            loadState = .limitReached
            return
        }

        guard let urlString = try? await extractURL(),
              let url = URL(string: urlString) else {
            loadState = .failed
            return
        }

        let hostname = url.host ?? ""
        loadState = .ready(url: url, hostname: hostname, title: urlString, description: nil, imageUrl: nil)

        if let (data, _) = try? await URLSession.shared.data(from: url),
           let html = String(data: data, encoding: .utf8),
           let og = DefaultOpenGraphData(html: html) {
            loadState = .ready(
                url: url,
                hostname: hostname,
                title: og.ogTitle ?? urlString,
                description: og.ogDescription,
                imageUrl: og.ogImageUrl
            )
        }
    }

    private func extractURL() async throws -> String? {
        guard let attachments = (extensionContext?.inputItems.first as? NSExtensionItem)?.attachments,
              !attachments.isEmpty else { return nil }

        for provider in attachments {
            if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                let item = try await provider.loadItem(forTypeIdentifier: UTType.url.identifier)
                return (item as? URL)?.absoluteString
            }
        }
        return nil
    }

    private func loadAvailableTagsAndGroups() {
        let defaults = UserDefaults(suiteName: "group.com.mattrighetti.Ulry")

        if let tagData = defaults?.data(forKey: "availableTags") {
            print("DEBUG: Found tag data in UserDefaults, size: \(tagData.count) bytes")
            if let tags = try? JSONDecoder().decode([SimpleTag].self, from: tagData) {
                print("DEBUG: Decoded \(tags.count) tags")
                self.availableTags = tags.sorted { $0.name < $1.name }
            } else {
                print("DEBUG: Failed to decode tags")
            }
        } else {
            print("DEBUG: No tag data found in UserDefaults")
        }

        if let groupData = defaults?.data(forKey: "availableGroups") {
            print("DEBUG: Found group data in UserDefaults, size: \(groupData.count) bytes")
            if let groups = try? JSONDecoder().decode([SimpleGroup].self, from: groupData) {
                print("DEBUG: Decoded \(groups.count) groups")
                self.availableGroups = groups.sorted { $0.name < $1.name }
            } else {
                print("DEBUG: Failed to decode groups")
            }
        } else {
            print("DEBUG: No group data found in UserDefaults")
        }
    }

    // MARK: - Actions

    private func save() {
        if case let .ready(url, _, _, _, _) = loadState {
            let tagIds = selectedTagIds.isEmpty ? nil : Array(selectedTagIds)
            requestsManager.add(url.absoluteString, note: note.isEmpty ? nil : note, tagIds: tagIds, groupId: selectedGroupId)
        }
        extensionContext?.completeRequest(returningItems: nil)
    }
}

// MARK: - Tag Pill

private struct TagPill: View {
    let tag: SimpleTag
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption2)
                }
                Text(tag.name)
                    .font(.caption)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                isSelected ?
                    Color(hex: tag.colorHex) ?? .blue :
                    Color(uiColor: .tertiarySystemGroupedBackground)
            )
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
    }
}

// MARK: - Custom Corner Radius

private struct CornerRadius: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(CornerRadius(radius: radius, corners: corners))
    }
}

// MARK: - Color extensions

extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard hex.count == 6, let intVal = UInt(hex, radix: 16) else { return nil }

        let r = Double((intVal >> 16) & 0xFF) / 255.0
        let g = Double((intVal >> 8) & 0xFF) / 255.0
        let b = Double(intVal & 0xFF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}
