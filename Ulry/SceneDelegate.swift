//
//  SceneDelegate.swift
//  Urly
//
//  Created by Mattia Righetti on 12/23/21.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import os
import UIKit
import SwiftUI
import Account
import Links
import LinksMetadata

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var account: Account = {
        let account = Account(dataFolder: Paths.dataFolder.absoluteString, type: .local, accountID: "id", imageCache: ImageStorage.shared)
        return account
    }()

    let addLinkRequestManger = ExtensionsAddLinkRequestsManager()
    private static var externalLinkImport = ExternalLinkImportState()

    var window: UIWindow?
    let themeController = ThemeController()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let window = UIWindow(windowScene: windowScene)
        
        themeController.handler = { [weak self] theme in
            UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveLinear, animations: { [weak self] in
                self?.window?.overrideUserInterfaceStyle = theme
            }, completion: .none)
        }
        
        let navigationController = UINavigationController(rootViewController: HomeCollectionView())
        window.rootViewController = navigationController
        
        window.makeKeyAndVisible()

        NotificationCenter.default.addObserver(self, selector: #selector(processExternalLinks), name: UIApplication.willEnterForegroundNotification, object: nil)

        self.window = window

        processExternalLinks()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        Task {
            await syncTagsAndGroupsToSharedDefaults()
        }
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.

        // Save changes in the application's managed object context when the application transitions to the background.
    }

    @objc private func processExternalLinks() {
        guard Self.externalLinkImport.begin() else { return }
        // Release the guard even when the queue is empty.
        let pendingLinks = addLinkRequestManger.pendingLinks
        guard !pendingLinks.isEmpty else {
            _ = Self.externalLinkImport.finish()
            return
        }

        os_log(.info, "moving \(pendingLinks.count) links from external file")

        Task {
            defer {
                if Self.externalLinkImport.finish() {
                    processExternalLinks()
                }
            }
            let toEnrich = await ExternalLinkImporter.persist(pendingLinks, account: account, queue: addLinkRequestManger)
            // Saving and draining the queue never wait for a preview or image.
            Task {
                for link in toEnrich { await account.enrichExternalLink(link) }
            }
        }
    }

    private func syncTagsAndGroupsToSharedDefaults() async {
        let defaults = UserDefaults(suiteName: "group.com.mattrighetti.Ulry")

        if let tags = try? await account.fetchAllTags(),
           let data = try? JSONEncoder().encode(tags) {
            defaults?.set(data, forKey: "availableTags")
        }

        if let groups = try? await account.fetchAllGroups(),
           let data = try? JSONEncoder().encode(groups) {
            defaults?.set(data, forKey: "availableGroups")
        }
    }
}


@MainActor
enum ExternalLinkImporter {
    /// A successful result means the request has a committed database record.
    /// Failed saves remain queued; preview work is left to the caller.
    static func persist(_ pendingLinks: [ExtensionsAddLinkRequests], account: Account, queue: ExtensionsAddLinkRequestsManager) async -> [Links.Link] {
        var links: [Links.Link] = []
        for pendingLink in pendingLinks {
            let link = Links.Link(url: pendingLink.url, note: pendingLink.note)
            link.id = pendingLink.id
            link.createdAt = Int32(clamping: pendingLink.date)
            link.updatedAt = link.createdAt

            // Attach tags if provided
            if let tagIds = pendingLink.tagIds {
                var tags = Set<Tag>()
                for tagIdStr in tagIds {
                    if let uuid = UUID(uuidString: tagIdStr),
                       let tag = try? account.fetchTag(with: uuid.uuidString) {
                        tags.insert(tag)
                    }
                }
                if !tags.isEmpty {
                    link.tags = tags
                }
            }

            // Attach group if provided
            if let groupIdStr = pendingLink.groupId,
               let uuid = UUID(uuidString: groupIdStr),
               let group = try? account.fetchGroup(with: uuid.uuidString) {
                link.group = group
            }

            links.append(link)
        }

        var toEnrich: [Links.Link] = []
        for (request, link) in zip(pendingLinks, links) {
            do {
                let inserted = try await account.importExternalLink(link)
                queue.remove([request])
                if inserted { toEnrich.append(link) }
            } catch {
                os_log(.error, "Could not import extension request: %{public}@", String(describing: error))
            }
        }
        return toEnrich
    }
}


/// Coalesces foreground events received while a batch is being persisted.
struct ExternalLinkImportState {
    private var isProcessing = false
    private var needsAnotherPass = false

    mutating func begin() -> Bool {
        if isProcessing {
            needsAnotherPass = true
            return false
        }
        isProcessing = true
        return true
    }

    mutating func finish() -> Bool {
        isProcessing = false
        let retry = needsAnotherPass
        needsAnotherPass = false
        return retry
    }
}
