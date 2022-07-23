//
//  AppDelegate.swift
//  Urly
//
//  Created by Mattia Righetti on 12/23/21.
//

import os
import UIKit
import CoreData
import FMDB

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
       
        UserDefaults.standard.register(defaults: [
            Defaults.openInApp.rawValue : false,
            Defaults.readMode.rawValue : false,
            Defaults.markReadOnOpen.rawValue: false,
            Defaults.theme.rawValue : Theme.system.rawValue,
            Defaults.orderBy.rawValue : OrderBy.newest.rawValue,
            Defaults.isPremium.rawValue : false
        ])
        
        NotificationCenter.default.addObserver(self, selector: #selector(copyLinkFromExternalDatabase), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        return true
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    @objc private func copyLinkFromExternalDatabase() {
        // Move every link from external database to internal one
        if Database.external.countLinks() > 0 {
            let links = Database.external.getAllLinks()
            os_log(.info, "moving \(links.count) links from external database to internal")
            
            LinkPipeline.main.save(links: links)
            for link in links {
                _ = Database.external.delete(link)
            }
        } else {
            os_log(.info, "no link found in external database")
        }
    }
}
