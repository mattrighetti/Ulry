//
//  HomeGlassComponents.swift
//  Ulry
//
//  Created by OpenAI Codex on 16/04/26.
//

import SwiftUI
import UIKit

struct HomeGlassCategoryCard: View {
    enum Style {
        case hero
        case row

        var cornerRadius: CGFloat {
            switch self {
            case .hero: return 30
            case .row: return 24
            }
        }

        var horizontalPadding: CGFloat {
            switch self {
            case .hero: return 20
            case .row: return 18
            }
        }

        var verticalPadding: CGFloat {
            switch self {
            case .hero: return 18
            case .row: return 16
            }
        }
    }

    let category: Category
    let style: Style

    private var accent: Color {
        Color(uiColor: category.cellContent.backgroundColor)
    }

    private var shadowRadius: CGFloat {
        switch style {
        case .hero: return 10
        case .row: return 6
        }
    }

    private var shadowYOffset: CGFloat {
        switch style {
        case .hero: return 4
        case .row: return 2
        }
    }

    var body: some View {
        GlassEffectContainer(spacing: 12) {
            content
                .padding(.horizontal, style.horizontalPadding)
                .padding(.vertical, style.verticalPadding)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .background {
                    RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous)
                        .fill(accent.opacity(0.18))
                        .overlay {
                            RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous)
                                .strokeBorder(.white.opacity(0.18), lineWidth: 1)
                        }
                }
                .glassEffect(
                    .regular.tint(accent.opacity(0.22)).interactive(),
                    in: .rect(cornerRadius: style.cornerRadius)
                )
                .shadow(color: accent.opacity(0.12), radius: shadowRadius, y: shadowYOffset)
        }
        .contentShape(RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous))
    }

    @ViewBuilder
    private var content: some View {
        switch style {
        case .hero:
            VStack(alignment: .leading, spacing: 14) {
                HomeGlassIconBadge(iconName: category.cellContent.icon, accent: accent, size: 52)

                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: 4) {
                    Text(category.cellContent.title)
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(heroSubtitle)
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(2, reservesSpace: true)
                }
            }
        case .row:
            HStack(spacing: 14) {
                HomeGlassIconBadge(iconName: category.cellContent.icon, accent: accent, size: 42)

                VStack(alignment: .leading, spacing: 3) {
                    Text(category.cellContent.title)
                        .font(.system(.headline, design: .rounded).weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text("Open collection")
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(10)
                    .glassEffect(.regular.tint(.white.opacity(0.08)), in: .circle)
            }
        }
    }

    private var heroSubtitle: String {
        switch category {
        case .all:
            return "Everything in one place"
        case .unread:
            return "Catch up quickly"
        case .starred:
            return "Keep essentials close"
        case .archived:
            return "Past items, out of the way"
        case .group:
            return "Curated collection"
        case .tag:
            return "Filtered by tag"
        }
    }
}

private struct HomeGlassIconBadge: View {
    let iconName: String?
    let accent: Color
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(accent.opacity(0.24))

            Circle()
                .strokeBorder(.white.opacity(0.18), lineWidth: 1)

            if let iconName {
                Image(systemName: iconName)
                    .font(.system(size: size * 0.36, weight: .semibold))
                    .foregroundStyle(.primary)
            }
        }
        .frame(width: size, height: size)
        .glassEffect(.regular.tint(accent.opacity(0.18)), in: .circle)
    }
}

final class HomeCollectionBackgroundView: UIView {
    private let gradientLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)

        isUserInteractionEnabled = false
        backgroundColor = .clear

        gradientLayer.locations = [0, 0.45, 1]
        layer.addSublayer(gradientLayer)
        updateGradientColors()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: HomeCollectionBackgroundView, _: UITraitCollection) in
            view.updateGradientColors()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        gradientLayer.frame = bounds
    }

    private func updateGradientColors() {
        gradientLayer.colors = [
            UIColor.systemBackground.resolvedColor(with: traitCollection).cgColor,
            UIColor.secondarySystemBackground.resolvedColor(with: traitCollection).cgColor,
            UIColor.systemBackground.resolvedColor(with: traitCollection).cgColor
        ]
    }
}
