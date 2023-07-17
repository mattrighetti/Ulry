//
//  AppReviewRequest.swift
//  Ulry
//
//  Created by Mattia Righetti on 11/04/23.
//  Copyright © 2023 Mattia Righetti. All rights reserved.
//

import Foundation
import StoreKit

struct AppReviewManager: Logging {
    private let appId = "1603982621"

    private func isReviewActive() async -> Bool {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "zgsoyvdvzdiwyavcuuos.functions.supabase.co"
        components.path = "/isAppPublished"

        guard let url = components.url else { return false }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(AppData.supabaseApiKey)", forHTTPHeaderField: "Authorization")
        request.setValue(AppData.userAgentSignature, forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 2

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let res = try JSONDecoder().decode(Bool.self, from: data)
            return res
        } catch {
            logger.debug("There was an error contacting Ulry APIs: \(error)")
            return false
        }
    }

    func openAppStoreForReview() {
        guard let writeReviewURL = URL(string: "https://apps.apple.com/app/id\(appId)?action=write-review")
        else { fatalError("Expected a valid URL") }
        
        UIApplication.shared.open(writeReviewURL, options: [:], completionHandler: nil)
    }

    let minimumReviewWorthyActionCount = 30.0

    func registerReviewWorthyAction(weighted: Double = 1.0) async {
        var actionCount: Double = UserDefaultsWrapper().get(key: .reviewWorthyActionCount)
        actionCount += 1.0 * weighted
        UserDefaultsWrapper().set(actionCount, forKey: .reviewWorthyActionCount)
    }

    public func requestReviewIfAppropriate(in view: UIView) async {
        let actionCount: Double = UserDefaultsWrapper().get(key: .reviewWorthyActionCount)

        guard actionCount >= minimumReviewWorthyActionCount else {
            return
        }

        let bundleVersionKey = kCFBundleVersionKey as String
        let currentVersion = Bundle.main.object(forInfoDictionaryKey: bundleVersionKey) as? String
        let lastVersion: String? = UserDefaultsWrapper().optionalGet(key: .lastReviewRequestAppVersion)

        guard lastVersion == nil || lastVersion != currentVersion else {
            return
        }

        if let windowScene = await view.window?.windowScene {
            await SKStoreReviewController.requestReview(in: windowScene)
        }

        UserDefaultsWrapper().set(0, forKey: .reviewWorthyActionCount)
        UserDefaultsWrapper().set(currentVersion, forKey: .lastReviewRequestAppVersion)
    }
}
