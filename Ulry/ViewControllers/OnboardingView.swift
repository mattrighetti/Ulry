//
//  OnboardingView.swift
//  Ulry
//
//  Created by Mattia Righetti on 14/02/23.
//  Copyright © 2023 Mattia Righetti. All rights reserved.
//

import SwiftUI

enum OnboardingPage: CaseIterable {
    case welcome
    case features

    static let fullOnboarding = OnboardingPage.allCases
    var shouldShowNextButton: Bool {

    switch self {
        case .welcome:
            return true
        default:
            return false
        }
    }
}

struct Feature: View {
    var image: String
    var title: String
    var subtitle: String

    var body: some View {
        HStack {
            Label(title: {
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.bottom, 1)
                    Text(subtitle)
                        .font(.callout)
                        .foregroundColor(.gray)
                }
            }, icon: {
                Image(systemName: image)
                    .font(.title2)
                    .padding(.trailing, 10)
            })
            Spacer()
        }.padding(.horizontal)
    }
}

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @State var currentIndex = 0

    var body: some View {
        VStack {
            TabView(selection: $currentIndex) {
                Container(title: "Welcome to\nUlry") {
                    VStack(alignment: .leading, spacing: 35) {
                        Feature(image: "tray", title: "Store your favorite links", subtitle: "Ulry will take care of all your beloved links")
                        Feature(image: "note.text", title: "Attach notes", subtitle: "Write and attach notes to your links so you won't forget a single thing")
                        Feature(image: "tag", title: "Categorise your links", subtitle: "Create an infinite number of tags and folders to better organise your links")
                        Feature(image: "magnifyingglass", title: "Fast search", subtitle: "Use the powerful search feature to look for your links even faster")
                    }
                }
                .tag(0)
                .frame(maxWidth: 400, maxHeight: 700)

                Container(title: "Peek at details and notes") {
                    VStack {
                        Image("onboarding-link-details")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(30)
                            .padding()

                        Text("Click on a link's image to show its details")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                }
                .tag(1)
                .frame(maxWidth: 400, maxHeight: 700)

                Container(title: "Save from\n Safari") {
                    VStack {
                        Image("onboarding-share-extension")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(30)
                            .padding(.horizontal)
                            .padding(.bottom, 10)

                        Text("Use the share extension to save links when you're not using the app")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                }
                .tag(2)
                .frame(maxWidth: 400, maxHeight: 700)
            }
            .tabViewStyle(PageTabViewStyle())
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            .animation(.easeInOut, value: currentIndex)
            .transition(.slide)
        }
    }

    @ViewBuilder
    private func Container(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack {
            Text(title)
                .font(.system(size: 40, weight: .black))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)

            Spacer()
            content()
            Spacer()
            Spacer()
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
            .previewDevice("iPhone SE (3rd generation)")
            .preferredColorScheme(.light)

        OnboardingView()
            .previewDevice("iPhone 14 Pro")
            .preferredColorScheme(.light)

        OnboardingView()
            .previewDevice("iPad (10th generation)")
            .preferredColorScheme(.light)
    }
}
