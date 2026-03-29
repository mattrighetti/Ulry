//
//  ShareViewController.swift
//  UlryShareExtension
//
//  Created by Matt on 10/12/2022.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import UIKit
import SwiftUI
import LinksMetadata
import UniformTypeIdentifiers

@objc(ShareExtensionViewController)
final class ShareViewController: UIHostingController<ShareRootView> {

    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: ShareRootView(extensionContext: nil))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        rootView = ShareRootView(extensionContext: extensionContext)
    }
}

// MARK: - Root layout

struct ShareRootView: View {
    let extensionContext: NSExtensionContext?

    var body: some View {
        if let ctx = extensionContext {
            ShareCardView(extensionContext: ctx)
        }
    }
}

// MARK: - Shapes

private struct TopRoundedRectangle: Shape {
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addArc(
            center: CGPoint(x: rect.minX + radius, y: rect.minY + radius),
            radius: radius, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        path.addArc(
            center: CGPoint(x: rect.maxX - radius, y: rect.minY + radius),
            radius: radius, startAngle: .degrees(270), endAngle: .degrees(0), clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Card

private enum LoadState {
    case loading
    case ready(url: URL, hostname: String, title: String)
    case limitReached
    case failed
}

private struct ShareCardView: View {
    let extensionContext: NSExtensionContext

    @State private var loadState: LoadState = .loading
    @State private var note = ""

    private let requestsManager = ExtensionsAddLinkRequestsManager()

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color(uiColor: .tertiaryLabel))
                .frame(width: 36, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 20)

            content
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
        .background {
            TopRoundedRectangle(radius: 20)
                .fill(Color(uiColor: .systemBackground))
                .ignoresSafeArea(edges: .bottom)
        }
        .task { await loadContent() }
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

        case let .ready(_, hostname, title):
            VStack(alignment: .leading, spacing: 0) {
                if !hostname.isEmpty {
                    Text(hostname)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 4)
                }
                Text(title)
                    .font(.headline)
                    .lineLimit(3)
                    .padding(.bottom, 20)

                TextField("Add a note (optional)", text: $note)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .background(Color(uiColor: .tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .submitLabel(.done)

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
                    extensionContext.completeRequest(returningItems: nil)
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
                    extensionContext.cancelRequest(withError: NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError))
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
        loadState = .ready(url: url, hostname: hostname, title: urlString)

        if let (data, _) = try? await URLSession.shared.data(from: url),
           let html = String(data: data, encoding: .utf8),
           let og = DefaultOpenGraphData(html: html),
           let ogTitle = og.ogTitle {
            loadState = .ready(url: url, hostname: hostname, title: ogTitle)
        }
    }

    private func extractURL() async throws -> String? {
        guard let attachments = (extensionContext.inputItems.first as? NSExtensionItem)?.attachments,
              !attachments.isEmpty else { return nil }

        for provider in attachments {
            if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                let item = try await provider.loadItem(forTypeIdentifier: UTType.url.identifier)
                return (item as? URL)?.absoluteString
            }
        }
        return nil
    }

    // MARK: - Actions

    private func save() {
        if case let .ready(url, _, _) = loadState {
            requestsManager.add(url.absoluteString, note: note.isEmpty ? nil : note)
        }
        extensionContext.completeRequest(returningItems: nil)
    }
}
