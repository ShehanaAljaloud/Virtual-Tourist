//
//  CoreDataStack.swift
//  VirtualTourist_
//
//  Created by Shehana Aljaloud on 22/06/2019.
//  Copyright © 2019 Shehana Aljaloud. All rights reserved.
//

import Foundation
import CoreData

class CoreDataStack {
    
    private init(){}
    
    class func getContext() -> NSManagedObjectContext {
        return CoreDataStack.persistentContainer.viewContext
    }
    
    static var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Virtual-Tourist")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    class func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
                print("Autosaving")
            } catch {
                print("Error while autosaving")
            }
        }
    }
}
