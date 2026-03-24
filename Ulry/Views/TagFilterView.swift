//
//  TagFilterView.swift
//  Ulry
//
//  Created on 2026-03-06.
//

import SwiftUI
import Links

final class TagFilterViewModel: ObservableObject {
    @Published var selectedTags: Set<Tag>
    let allTags: [Tag]
    var onApply: ((Set<Tag>) -> Void)?

    init(allTags: [Tag], selectedTags: Set<Tag>) {
        self.allTags = allTags
        self.selectedTags = selectedTags
    }
}

struct TagFilterView: View {
    @ObservedObject var viewModel: TagFilterViewModel
    var dismiss: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            ZStack {
                Text("Filter by Tags")
                    .font(.headline)

                HStack {
                    Button("Cancel") {
                        dismiss?()
                    }
                    .font(.body)
                    Spacer()

                    if !viewModel.selectedTags.isEmpty {
                        Button("Clear") {
                            withAnimation { viewModel.selectedTags.removeAll() }
                        }
                        .font(.body)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 24)
            .padding(.bottom, 18)

            Divider()

            if viewModel.allTags.isEmpty {
                Spacer()
                Text("No tags yet")
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                ScrollView {
                    WrappingHStack(tags: viewModel.allTags, selectedTags: $viewModel.selectedTags)
                        .padding()
                }

                Divider()

                Button {
                    viewModel.onApply?(viewModel.selectedTags)
                    dismiss?()
                } label: {
                    Text(buttonTitle)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 8)
            }
        }
        .background(Color(UIColor.systemBackground))
    }

    private var buttonTitle: String {
        if viewModel.selectedTags.isEmpty {
            return "Show All"
        }
        let count = viewModel.selectedTags.count
        return "Filter by \(count) Tag\(count == 1 ? "" : "s")"
    }
}

private struct WrappingHStack: View {
    let tags: [Tag]
    @Binding var selectedTags: Set<Tag>
    @State private var totalHeight: CGFloat = .zero

    var body: some View {
        GeometryReader { geometry in
            generateContent(in: geometry)
        }
        .frame(height: totalHeight)
    }

    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width: CGFloat = 0
        var height: CGFloat = 0

        return ZStack(alignment: .topLeading) {
            ForEach(tags, id: \.id) { tag in
                TagPill(tag: tag, isSelected: selectedTags.contains(tag)) {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        if selectedTags.contains(tag) {
                            selectedTags.remove(tag)
                        } else {
                            selectedTags.insert(tag)
                        }
                    }
                }
                .padding(.trailing, 8)
                .padding(.bottom, 10)
                .alignmentGuide(.leading) { d in
                    if abs(width - d.width) > geometry.size.width {
                        width = 0
                        height -= d.height
                    }
                    let result = width
                    if tag.id == tags.last?.id {
                        width = 0
                    } else {
                        width -= d.width
                    }
                    return result
                }
                .alignmentGuide(.top) { _ in
                    let result = height
                    if tag.id == tags.last?.id {
                        height = 0
                    }
                    return result
                }
            }
        }
        .background(viewHeightReader($totalHeight))
    }

    private func viewHeightReader(_ binding: Binding<CGFloat>) -> some View {
        GeometryReader { geometry -> Color in
            let rect = geometry.frame(in: .local)
            DispatchQueue.main.async {
                binding.wrappedValue = rect.size.height
            }
            return .clear
        }
    }
}

private struct TagPill: View {
    let tag: Tag
    let isSelected: Bool
    let action: () -> Void

    var tagColor: Color {
        Color(hex: tag.colorHex) ?? .blue
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Circle()
                    .fill(tagColor)
                    .frame(width: 10, height: 10)
                Text(tag.name)
                    .font(.subheadline.weight(.medium))
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                isSelected
                    ? tagColor.opacity(0.2)
                    : Color(UIColor.secondarySystemBackground)
            )
            .foregroundColor(isSelected ? tagColor : .primary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? tagColor.opacity(0.6) : Color(UIColor.separator), lineWidth: isSelected ? 1.5 : 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}
