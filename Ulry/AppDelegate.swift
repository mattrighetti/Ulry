//
//  AppDelegate.swift
//  Urly
//
//  Created by Mattia Righetti on 12/23/21.
//

import UIKit
import CoreData
import FMDB
import FMDBMigrationManager

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var database: FMDatabase {
        // 1 - Get filePath of the SQLite file
        let fileURL = try! FileManager.default
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("ulry.sqlite")
        
        // 2 - Create FMDatabase from filePath
        let db = FMDatabase(url: fileURL)
        return db
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        setupDatabase()
        
        UserDefaults.standard.register(defaults: [
            Defaults.openInApp.rawValue : false,
            Defaults.readMode.rawValue : false,
            Defaults.markReadOnOpen.rawValue: false,
            Defaults.theme.rawValue : Theme.system.rawValue,
            Defaults.orderBy.rawValue : LinksTableViewController.OrderBy.newest.rawValue,
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
    
    func setupDatabase() {
        let manager = FMDBMigrationManager(database: database, migrationsBundle: .main)!
        if !manager.hasMigrationsTable {
            try! manager.createMigrationsTable()
        }
        
        do {
            try manager.migrateDatabase(toVersion: UInt64.max, progress: { progress in
                print(progress!)
            })
        } catch {
            print("error: \(error)")
            fatalError()
        }
    }
}
