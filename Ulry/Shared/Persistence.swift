//
//  Persistence.swift
//  Urly
//
//  Created by Mattia Righetti on 1/2/22.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "Urly")
        
        let storeURL = URL.storeURL(for: "group.com.mattrighetti.Ulry", databaseName: "Ulry")
        let storeDescription = NSPersistentStoreDescription(url: storeURL)
        
        container.persistentStoreDescriptions = [storeDescription]
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
    }
}
