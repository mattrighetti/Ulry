//
//  AppDelegate.swift
//  Urly
//
//  Created by Mattia Righetti on 12/23/21.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import os
import UIKit
import CoreData
import LinksDatabase
import FMDB

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let startupTasks: [StartupTask] = [
            RegisterInitialValuesForUserDefaultsStartupTask()
        ]

        startupTasks.forEach { $0.run() }

        Task {
            await AppReviewManager().registerReviewWorthyAction(weighted: 0.1)
        }
        
        return true
    }
    
    // MARK: - UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}

