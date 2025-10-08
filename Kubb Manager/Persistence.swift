//
//  Persistence.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 9/23/25.
//

import CoreData

// MARK: - Core Data Persistence Controller
// This struct manages the Core Data stack for the Kubb Manager app
// It handles database initialization, CloudKit integration, and data persistence
struct PersistenceController {
    // MARK: - Singleton Instance
    // Shared instance ensures only one database connection throughout the app
    // This prevents multiple Core Data stacks and ensures data consistency
    static let shared = PersistenceController()

    // MARK: - Preview Context
    // Special instance for SwiftUI previews with sample data
    // @MainActor ensures UI updates happen on the main thread
    // This is essential for SwiftUI previews to work correctly
    @MainActor
    static let preview: PersistenceController = {
        // Create an in-memory store for previews (data doesn't persist)
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create sample data for previews
        // This loop creates 10 sample items with timestamps
        for _ in 0..<10 {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()
        }
        
        // Save the sample data to the preview context
        do {
            try viewContext.save()
        } catch {
            // Error handling for preview data creation
            // fatalError is acceptable here since it's only for previews
            // In production code, this would be handled more gracefully
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    // MARK: - Core Data Container
    // NSPersistentCloudKitContainer integrates Core Data with CloudKit
    // This enables automatic syncing of data across user's devices
    let container: NSPersistentCloudKitContainer

    // MARK: - Initialization
    // Sets up the Core Data stack with optional in-memory storage
    init(inMemory: Bool = false) {
        // Initialize the CloudKit-enabled Core Data container
        // "Kubb_Manager" matches the .xcdatamodeld filename
        container = NSPersistentCloudKitContainer(name: "Kubb_Manager")
        
        // Configure in-memory storage for testing/previews
        if inMemory {
            // /dev/null is a special file that discards all data written to it
            // This creates a temporary database that exists only in memory
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // Load the persistent store (database file)
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Handle database loading errors
                // fatalError is used here for development, but should be replaced
                // with proper error handling in production apps

                /*
                 Common database loading errors include:
                 * The parent directory doesn't exist or can't be created
                 * The database file is locked (device locked, permissions)
                 * Device is out of storage space
                 * Database schema migration failed
                 * CloudKit synchronization issues
                 
                 Check the error message and userInfo for specific details
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        // Enable automatic merging of changes from parent context
        // This ensures that changes made in background contexts are
        // automatically reflected in the main context and UI
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
