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
        
        // Step 1: Download all data from CloudKit and save to local storage
        await downloadAllCloudKitData()
        
        // Step 2: Notify all managers to refresh their data from local storage
        NotificationCenter.default.post(name: .dataRefreshRequired, object: nil)
        
        print("✅ Full sync completed - CloudKit data synced to local storage")
    }
    
    private func downloadAllCloudKitData() async {
        print("📥 Downloading all data from CloudKit...")
        
        do {
            // Download practice sessions
            let practiceSessions = try await cloudKitManager.fetchSessions()
            print("📥 Downloaded \(practiceSessions.count) practice sessions")
            localStorage.savePracticeSessions(practiceSessions)
            
            // Download inkast blast sessions
            let inkastBlastSessions = await cloudKitManager.fetchInkastBlastSessions()
            print("📥 Downloaded \(inkastBlastSessions.count) inkast blast sessions")
            localStorage.saveInkastBlastSessions(inkastBlastSessions)
            
            // Download baseball kubb sessions
            let baseballKubbSessions = try await cloudKitManager.fetchBaseballKubbSessions()
            print("📥 Downloaded \(baseballKubbSessions.count) baseball kubb sessions")
            localStorage.saveBaseballKubbSessionsBulk(baseballKubbSessions)
            
            // Download full game sim sessions
            let fullGameSimSessions = await cloudKitManager.fetchFullGameSimSessions()
            print("📥 Downloaded \(fullGameSimSessions.count) full game sim sessions")
            
            // Deduplicate before saving
            let dedupedFullGameSim = deduplicateFullGameSimSessions(fullGameSimSessions)
            print("🧹 Deduplicated to \(dedupedFullGameSim.count) full game sim sessions")
            localStorage.saveFullGameSimSessions(dedupedFullGameSim)
            
        } catch {
            print("❌ Error downloading CloudKit data: \(error)")
        }
    }
    
    
    // MARK: - Deduplication
    
    private func deduplicateFullGameSimSessions(_ sessions: [FullGameSimSessionStruct]) -> [FullGameSimSessionStruct] {
        // Group by ID
        let grouped = Dictionary(grouping: sessions) { $0.id }
        
        var deduplicated: [FullGameSimSessionStruct] = []
        
        for (sessionId, sessionGroup) in grouped {
            if sessionGroup.count == 1 {
                // No duplicates
                deduplicated.append(sessionGroup[0])
            } else {
                // Multiple sessions with same ID - pick the best one
                print("⚠️ Found \(sessionGroup.count) duplicates for session ID: \(sessionId)")
                
                let bestSession = selectBestFullGameSimSession(from: sessionGroup)
                deduplicated.append(bestSession)
                
                print("✅ Kept session: round=\(bestSession.currentRound), isComplete=\(bestSession.isComplete), isPaused=\(bestSession.isPaused), modifiedAt=\(bestSession.modifiedAt)")
            }
        }
        
        return deduplicated
    }
    
    private func selectBestFullGameSimSession(from sessions: [FullGameSimSessionStruct]) -> FullGameSimSessionStruct {
        // Priority logic:
        // 1. Prefer completed sessions
        // 2. If both incomplete, prefer higher currentRound (more progress)
        // 3. If same round, prefer most recent modifiedAt
        
        return sessions.max { session1, session2 in
            // If completion status differs, prefer complete
            if session1.isComplete != session2.isComplete {
                return !session1.isComplete // session2 is complete, so it wins
            }
            
            // If both have same completion status, prefer higher round number
            if session1.currentRound != session2.currentRound {
                return session1.currentRound < session2.currentRound
            }
            
            // If same round, prefer most recent modification
            return session1.modifiedAt < session2.modifiedAt
        } ?? sessions[0]
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
            // Notify all managers to refresh their data from local storage
            NotificationCenter.default.post(name: .dataRefreshRequired, object: nil)
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let dataRefreshRequired = Notification.Name("dataRefreshRequired")
}
