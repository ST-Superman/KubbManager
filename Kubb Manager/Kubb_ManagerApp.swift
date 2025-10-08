//
//  Kubb_ManagerApp.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 9/23/25.
//

import SwiftUI

// MARK: - Main App Entry Point
// This is the main entry point for the Kubb Manager iOS app
// The @main attribute tells SwiftUI this is the starting point of the app

@main
struct Kubb_ManagerApp: App {
    // MARK: - State Management
    // @StateObject creates and manages the lifecycle of AppInitializationManager
    // This manager handles app startup tasks like CloudKit setup, data migration, etc.
    // Using .shared ensures we have a single instance throughout the app (Singleton pattern)
    @StateObject private var appInitializationManager = AppInitializationManager.shared
    
    // MARK: - App Body
    // This defines the main scene structure for the app
    var body: some Scene {
        WindowGroup {
            // ContentView is the root view that contains all the app's UI
            ContentView()
                // .task modifier runs async code when the view appears
                // This ensures app initialization happens before the UI is shown
                .task {
                    // Initialize the app with any required setup tasks
                    // This might include CloudKit authentication, data loading, etc.
                    await appInitializationManager.initializeApp()
                }
        }
    }
}
