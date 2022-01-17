//
//  CoreDataStack.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/16/22.
//

import CoreData
import Foundation

class CoreDataStack {
    private let modelName: String
    static var shared = CoreDataStack(modelName: "Urly")
    
    lazy var managedContext: NSManagedObjectContext = {
        return self.storeContainer.viewContext
    }()
    
    private init(modelName: String) {
        self.modelName = modelName
    }
    
    private lazy var storeContainer: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: self.modelName)
        let storeURL = URL.storeURL(for: "group.com.mattrighetti.Ulry", databaseName: "Ulry")
        let storeDescription = NSPersistentStoreDescription(url: storeURL)
        container.persistentStoreDescriptions = [storeDescription]
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                print("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        return container
    }()
    
    func saveContext() {
        guard managedContext.hasChanges else { return }
        
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Unresolved error \(error), \(error.userInfo)")
        }
    }
}
