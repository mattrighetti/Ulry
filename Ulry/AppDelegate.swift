//
//  AppDelegate.swift
//  Urly
//
//  Created by Mattia Righetti on 12/23/21.
//

import UIKit
import CoreData
import FMDB

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
       
        Database.shared = Database()
        
        UserDefaults.standard.register(defaults: [
            Defaults.openInApp.rawValue : false,
            Defaults.readMode.rawValue : false,
            Defaults.markReadOnOpen.rawValue: false,
            Defaults.theme.rawValue : Theme.system.rawValue,
            Defaults.orderBy.rawValue : OrderBy.newest.rawValue,
            Defaults.isPremium.rawValue : false
        ])
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}
