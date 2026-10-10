import UIKit
import SwiftUI
import LinksMetadata
import UniformTypeIdentifiers

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
    @State private var showsNoteField = false
    @State private var saveFailed = false
    @State private var isSaving = false
    @State private var tagSearch = ""
    @State private var selectedTagIds = Set<String>()
    @State private var selectedGroupId: String?
    @State private var availableTags: [SimpleTag] = []
    @State private var availableGroups: [SimpleGroup] = []
    @FocusState private var noteIsFocused: Bool

    private let requestsManager = ExtensionsAddLinkRequestsManager()

    init(extensionContext: NSExtensionContext?) {
        self.extensionContext = extensionContext
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                content
            }
            .padding(24)
            .frame(maxWidth: 600, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color(uiColor: .systemGroupedBackground))
        .safeAreaInset(edge: .top, spacing: 0) { header }
        .safeAreaInset(edge: .bottom, spacing: 0) { footer }
        .task {
            guard extensionContext != nil else { return }
            loadAvailableTagsAndGroups()
            await loadContent()
        }
        .alert("Couldn't save link", isPresented: $saveFailed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please try saving again.")
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "bookmark.fill")
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 42, height: 42)
                .background(.tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 2) {
                Text("Save to Ulry")
                    .font(.system(.headline, design: .rounded))
                Text("Read it when you’re ready.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: dismiss) {
                Image(systemName: "xmark")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
                    .background(.quaternary, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Cancel")
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(.bar)
    }

    @ViewBuilder
    private var footer: some View {
        if case .ready = loadState {
            Button(action: save) {
                Text(isSaving ? "Saving…" : "Save")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 20)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle(radius: 14))
            .controlSize(.large)
            .disabled(isSaving)
            .padding(.horizontal, 24)
            .padding(.top, 10)
            .padding(.bottom, 8)
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
            .background(.bar)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch loadState {
        case .loading:
            VStack(spacing: 14) {
                ProgressView()
                Text("Getting your link ready…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 60)
        case let .ready(_, hostname, title, description, imageUrl):
            linkPreview(hostname: hostname, title: title, description: description, imageUrl: imageUrl)
            noteField
            if !availableGroups.isEmpty { groupPicker }
            if !availableTags.isEmpty { tagPicker }
        case .limitReached:
            statusCard(icon: "tray.full", title: "Time to catch up", message: "Open Ulry to import your saved links. Then there’ll be room for more.")
        case .failed:
            statusCard(icon: "link", title: "Couldn't read this link", message: "Try sharing the page again from your browser.")
        }
    }

    private func linkPreview(hostname: String, title: String, description: String?, imageUrl: String?) -> some View {
        HStack(alignment: .top, spacing: 16) {
            AsyncImage(url: imageUrl.flatMap(URL.init(string:))) { phase in
                if case .success(let image) = phase {
                    image.resizable().scaledToFill()
                } else {
                    ZStack {
                        Color.accentColor.opacity(0.08)
                        Image(systemName: "doc.text")
                            .font(.title2)
                            .foregroundStyle(.tint)
                    }
                }
            }
            .frame(width: 76, height: 86)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 8) {
                Text(hostname.replacingOccurrences(of: "www.", with: ""))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(title)
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                if let description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(18)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24))
    }

    @ViewBuilder
    private var noteField: some View {
        if showsNoteField {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeading("Note", detail: "Optional")
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Image(systemName: "square.and.pencil")
                        .foregroundStyle(.secondary)
                    TextField("What made this worth saving?", text: $note, axis: .vertical)
                        .lineLimit(1...5)
                        .focused($noteIsFocused)
                        .onAppear { noteIsFocused = true }
                }
                .font(.subheadline)
                .padding(16)
                .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
            }
        } else {
            Button {
                withAnimation(.snappy(duration: 0.2)) { showsNoteField = true }
            } label: {
                Label("Add note", systemImage: "square.and.pencil")
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 14)
                    .frame(minHeight: 44)
                    .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 13))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.tint)
        }
    }

    private var groupPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeading("Group")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 10)], spacing: 10) {
                ForEach(availableGroups, id: \.id) { group in
                    groupCard(name: group.name, icon: group.iconName, color: shareColor(hex: group.colorHex) ?? .accentColor, id: group.id)
                }
            }
        }
    }

    private func groupCard(name: String, icon: String, color: Color, id: String) -> some View {
        let selected = selectedGroupId == id
        return Button {
            noteIsFocused = false
            withAnimation(.snappy(duration: 0.2)) { selectedGroupId = selected ? nil : id }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(color)
                    .frame(width: 34, height: 34)
                    .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                Text(name)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.subheadline)
                    .foregroundStyle(selected ? Color.accentColor : Color(uiColor: .tertiaryLabel))
            }
            .padding(12)
            .frame(minHeight: 64)
            .background(selected ? Color.accentColor.opacity(0.06) : Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(selected ? Color.accentColor.opacity(0.65) : .clear, lineWidth: 1.5)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityHint(selected ? "Tap to remove this group" : "Tap to select this group")
    }

    private var filteredTags: [SimpleTag] {
        let query = tagSearch.trimmingCharacters(in: .whitespacesAndNewlines)
        return query.isEmpty ? availableTags : availableTags.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    private var tagPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeading("Tags", detail: selectedTagIds.isEmpty ? nil : "\(selectedTagIds.count) selected")
            if availableTags.count > 8 {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField("Find a tag", text: $tagSearch)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                .font(.subheadline)
                .padding(14)
                .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
            }
            TagFlowLayout(spacing: 8) {
                ForEach(filteredTags, id: \.id) { tag in
                    tagButton(tag)
                }
            }
            if filteredTags.isEmpty {
                Text("No matching tags")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func tagButton(_ tag: SimpleTag) -> some View {
        let selected = selectedTagIds.contains(tag.id)
        return Button {
            noteIsFocused = false
            withAnimation(.snappy(duration: 0.2)) {
                if selected { selectedTagIds.remove(tag.id) }
                else { selectedTagIds.insert(tag.id) }
            }
        } label: {
            HStack(spacing: 8) {
                Circle()
                    .fill(shareColor(hex: tag.colorHex) ?? .accentColor)
                    .frame(width: 7, height: 7)
                Text(tag.name)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(2)
                if selected {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                }
            }
            .foregroundStyle(selected ? Color.accentColor : .primary)
            .padding(.horizontal, 14)
            .frame(minHeight: 44)
            .padding(.vertical, 2)
            .background(selected ? Color.accentColor.opacity(0.1) : Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 13))
            .overlay {
                RoundedRectangle(cornerRadius: 13)
                    .strokeBorder(selected ? Color.accentColor.opacity(0.4) : .clear, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func sectionHeading(_ title: String, detail: String? = nil) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(.system(.headline, design: .rounded))
            Spacer()
            if let detail {
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private func statusCard(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundStyle(.secondary)
                .padding(20)
                .background(.quaternary, in: Circle())
            Text(title).font(.system(.title2, design: .rounded).weight(.semibold))
            Text(message).font(.subheadline).foregroundStyle(.secondary)
            Button("Close", action: dismiss).buttonStyle(.bordered).controlSize(.large)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private func dismiss() {
        extensionContext?.cancelRequest(withError: NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError))
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

        if let tagData = defaults?.data(forKey: "availableTags"),
           let tags = try? JSONDecoder().decode([SimpleTag].self, from: tagData) {
            self.availableTags = tags.sorted { $0.name < $1.name }
        }

        if let groupData = defaults?.data(forKey: "availableGroups"),
           let groups = try? JSONDecoder().decode([SimpleGroup].self, from: groupData) {
            self.availableGroups = groups.sorted { $0.name < $1.name }
        }
    }

    // MARK: - Actions

    private func save() {
        guard !isSaving, extensionContext != nil else { return }
        noteIsFocused = false
        if case let .ready(url, _, _, _, _) = loadState {
            let tagIds = selectedTagIds.isEmpty ? nil : Array(selectedTagIds)
            guard requestsManager.add(url.absoluteString, note: note.isEmpty ? nil : note, tagIds: tagIds, groupId: selectedGroupId) else {
                if requestsManager.canSaveMoreLinks {
                    saveFailed = true
                } else {
                    loadState = .limitReached
                }
                return
            }
        }
        isSaving = true
        extensionContext?.completeRequest(returningItems: nil)
    }
}

// MARK: - Wrapping tags

private struct TagFlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 320
        return arrange(subviews, width: width).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(subviews, width: bounds.width)
        for (index, point) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y), anchor: .topLeading, proposal: ProposedViewSize(result.sizes[index]))
        }
    }

    private func arrange(_ subviews: Subviews, width: CGFloat) -> (size: CGSize, positions: [CGPoint], sizes: [CGSize]) {
        let width = max(0, width)
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var positions: [CGPoint] = []
        var sizes: [CGSize] = []
        for subview in subviews {
            let ideal = subview.sizeThatFits(.unspecified)
            let size = subview.sizeThatFits(ProposedViewSize(width: min(ideal.width, width), height: nil))
            if x > 0 && x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            sizes.append(size)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return (CGSize(width: width, height: y + rowHeight), positions, sizes)
    }
}

// MARK: - Color extensions

private func shareColor(hex: String) -> Color? {
    let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
    guard hex.count == 6, let intVal = UInt(hex, radix: 16) else { return nil }
    return Color(
        red: Double((intVal >> 16) & 0xFF) / 255.0,
        green: Double((intVal >> 8) & 0xFF) / 255.0,
        blue: Double(intVal & 0xFF) / 255.0
    )
}

#if DEBUG
extension ShareCardView {
    init(preview: Bool) {
        self.init(extensionContext: nil)
        _loadState = State(initialValue: .ready(
            url: URL(string: "https://example.com/design")!,
            hostname: "example.com",
            title: "Good design makes room for the things that matter",
            description: "A few thoughtful ideas for a slower, more intentional digital life.",
            imageUrl: nil
        ))
        _availableGroups = State(initialValue: [
            SimpleGroup(id: "design", name: "Design", colorHex: "7C66DC", iconName: "square.stack.3d.up"),
            SimpleGroup(id: "reading", name: "Weekend reads", colorHex: "CA7949", iconName: "book"),
            SimpleGroup(id: "ideas", name: "Ideas", colorHex: "388978", iconName: "lightbulb")
        ])
        _availableTags = State(initialValue: [
            SimpleTag(id: "inspiration", name: "Inspiration", colorHex: "7C66DC"),
            SimpleTag(id: "essays", name: "Essays", colorHex: "CA7949"),
            SimpleTag(id: "creative", name: "Creative work", colorHex: "388978"),
            SimpleTag(id: "slow", name: "Slow living", colorHex: "B6597E")
        ])
        _selectedGroupId = State(initialValue: "design")
        _selectedTagIds = State(initialValue: ["inspiration", "creative"])
    }
}

#endif
