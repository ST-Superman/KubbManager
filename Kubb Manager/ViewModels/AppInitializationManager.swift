//
//  AppInitializationManager.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 1/15/25.
//

import Foundation
import CloudKit

@MainActor
class AppInitializationManager: ObservableObject {
    static let shared = AppInitializationManager()
    
    @Published var isInitialized = false
    @Published var isInitializing = false
    @Published var initializationError: String?
    
    private let cloudKitManager = CloudKitManager.shared
    private let localStorage = LocalStorageManager.shared
    
    private init() {}
    
    // MARK: - App Initialization
    
    func initializeApp() async {
        guard !isInitializing else { return }
        
        isInitializing = true
        initializationError = nil
        
        print("🚀 Starting app initialization...")
        
        // Step 1: Check CloudKit account status
        await cloudKitManager.checkAccountStatus()
        
        if cloudKitManager.isSignedIn {
            // Step 2: Perform full sync (CloudKit → Local → CloudKit)
            await performFullSync()
        } else {
            // Step 3: Load from local storage only
            await loadFromLocalStorage()
        }
        
        isInitialized = true
        print("✅ App initialization completed successfully")
        
        isInitializing = false
    }
    
    // MARK: - Full Sync Process
    
    private func performFullSync() async {
        print("🔄 Starting full sync process...")
        
        // Step 1: Download all data from CloudKit
        await downloadAllCloudKitData()
        
        // Step 2: Clean up old and empty records
        await cloudKitManager.cleanupOldAndEmptyRecords()
        
        // Step 3: Sync local data to CloudKit (upload any local-only changes)
        await cloudKitManager.syncLocalDataToCloudKit()
        
        // Step 4: Update local storage with cleaned CloudKit data
        await updateLocalStorageWithCloudKitData()
        
        print("✅ Full sync completed")
    }
    
    private func downloadAllCloudKitData() async {
        print("📥 Downloading all data from CloudKit...")
        
        do {
            // Download practice sessions
            let practiceSessions = try await cloudKitManager.fetchSessions()
            print("📥 Downloaded \(practiceSessions.count) practice sessions")
            
            // Download inkast blast sessions
            let inkastBlastSessions = await cloudKitManager.fetchInkastBlastSessions()
            print("📥 Downloaded \(inkastBlastSessions.count) inkast blast sessions")
            
            // Download baseball kubb sessions
            let baseballKubbSessions = try await cloudKitManager.fetchBaseballKubbSessions()
            print("📥 Downloaded \(baseballKubbSessions.count) baseball kubb sessions")
            
        } catch {
            print("❌ Error downloading CloudKit data: \(error)")
        }
    }
    
    private func updateLocalStorageWithCloudKitData() async {
        print("💾 Updating local storage with cleaned CloudKit data...")
        
        do {
            // Get the cleaned data from CloudKit
            let practiceSessions = try await cloudKitManager.fetchSessions()
            let inkastBlastSessions = await cloudKitManager.fetchInkastBlastSessions()
            let baseballKubbSessions = try await cloudKitManager.fetchBaseballKubbSessions()
            
            // Update local storage with the cleaned data
            localStorage.savePracticeSessions(practiceSessions)
            localStorage.saveInkastBlastSessions(inkastBlastSessions)
            localStorage.saveBaseballKubbSessionsBulk(baseballKubbSessions)
            
            print("✅ Local storage updated with cleaned CloudKit data")
            
        } catch {
            print("❌ Error updating local storage: \(error)")
        }
    }
    
    private func loadFromLocalStorage() async {
        print("📱 Loading from local storage only...")
        // Local storage is already loaded by the individual managers
        // This is just a fallback when CloudKit is not available
    }
    
    // MARK: - Refresh Data
    
    func refreshAllData() async {
        print("🔄 Manual refresh triggered...")
        
        if cloudKitManager.isSignedIn {
            await performFullSync()
        } else {
            await loadFromLocalStorage()
        }
        
        // Notify all managers to refresh their data
        NotificationCenter.default.post(name: .dataRefreshRequired, object: nil)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let dataRefreshRequired = Notification.Name("dataRefreshRequired")
}
