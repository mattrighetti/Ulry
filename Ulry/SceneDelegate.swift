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
        guard addLinkRequestManger.getCache().count > 0 else { return }
        os_log(.info, "moving \(self.addLinkRequestManger.externalCache.count) links from external file")
        let links = addLinkRequestManger.externalCache.values.map { Link(url: $0.url, note: $0.note) }
        
        Task {
            await account.insertBatch(links: links)
            addLinkRequestManger.persistCache()
        }
    }
}

