//
//  LocalStorageManager.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 9/23/25.
//

import Foundation

// MARK: - Local Data Storage Manager
// This class handles all local data persistence using UserDefaults
// It serves as a fallback when CloudKit is unavailable and manages all session data

@MainActor
class LocalStorageManager: ObservableObject {
    // MARK: - Singleton Pattern
    // Shared instance ensures consistent data access throughout the app
    static let shared = LocalStorageManager()
    
    // MARK: - Storage Components
    // UserDefaults provides simple key-value storage for app preferences and data
    private let userDefaults = UserDefaults.standard
    
    // Key used to store practice sessions in UserDefaults
    // This key identifies where session data is stored in the user's device storage
    private let sessionsKey = "PracticeSessions"
    
    // MARK: - Initialization
    // Private initializer ensures singleton pattern
    private init() {}
    
    // MARK: - Practice Session Operations
    
    /// Saves a practice session to local storage
    /// Updates existing session if it exists, or adds new session if it doesn't
    /// Sessions are automatically sorted by creation date (newest first)
    func saveSession(_ session: PracticeSession) {
        // Load all existing sessions from storage
        var sessions = loadSessions()
        
        // Check if session already exists (by unique ID)
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            // Update existing session at found index
            sessions[index] = session
        } else {
            // Add new session to the array
            sessions.append(session)
        }
        
        // Sort sessions by creation date (newest first) for consistent ordering
        sessions.sort { $0.createdAt > $1.createdAt }
        
        // Save the updated sessions array back to storage
        saveSessions(sessions)
    }
    
    /// Loads all practice sessions from local storage
    /// Returns empty array if no sessions exist or if there's an error
    func loadSessions() -> [PracticeSession] {
        // Try to get session data from UserDefaults
        guard let data = userDefaults.data(forKey: sessionsKey) else {
            // No data found - return empty array (first app launch)
            return []
        }
        
        do {
            // Decode JSON data back into PracticeSession objects
            let sessions = try JSONDecoder().decode([PracticeSession].self, from: data)
            return sessions
        } catch {
            // Handle decoding errors (corrupted data, format changes, etc.)
            print("Error loading sessions from local storage: \(error)")
            return []
        }
    }
    
    /// Finds and returns the most recent incomplete practice session
    /// An incomplete session is one that was started today but not finished
    /// This allows users to resume their practice session if they close the app
    func fetchIncompleteSession() -> PracticeSession? {
        let sessions = loadSessions()
        print("🔍 Checking for incomplete sessions...")
        print("Total sessions: \(sessions.count)")
        
        // Debug logging to help troubleshoot session state
        for session in sessions {
            let calendar = Calendar.current
            let isToday = calendar.isDateInToday(session.date)
            let isTargetReached = session.isTargetReached
            let isIncomplete = session.isIncomplete
            
            print("Session \(session.id):")
            print("  - Date: \(session.date)")
            print("  - Is today: \(isToday)")
            print("  - Target: \(session.target)")
            print("  - Kubbs: \(session.totalKubbs)")
            print("  - Target reached: \(isTargetReached)")
            print("  - Is incomplete: \(isIncomplete)")
            print("  - Is complete: \(session.isComplete)")
        }
        
        // Find first session that meets incomplete criteria
        // (started today, target not reached, not marked complete)
        let incompleteSession = sessions.first { $0.isIncomplete }
        if let session = incompleteSession {
            print("✅ Found incomplete session: \(session.id)")
        } else {
            print("❌ No incomplete session found")
        }
        
        return incompleteSession
    }
    
    func deleteSession(_ session: PracticeSession) {
        var sessions = loadSessions()
        sessions.removeAll { $0.id == session.id }
        saveSessions(sessions)
    }
    
    // MARK: - Private Methods
    
    private func saveSessions(_ sessions: [PracticeSession]) {
        do {
            let data = try JSONEncoder().encode(sessions)
            userDefaults.set(data, forKey: sessionsKey)
        } catch {
            print("Error saving sessions to local storage: \(error)")
        }
    }
    
    // MARK: - Data Management
    
    func clearAllData() {
        userDefaults.removeObject(forKey: sessionsKey)
    }
    
    func exportData() -> Data? {
        let sessions = loadSessions()
        return try? JSONEncoder().encode(sessions)
    }
    
    // MARK: - Baseball Kubb Sessions
    
    func saveBaseballKubbSession(_ session: BaseballKubbSession) {
        var sessions = loadBaseballKubbSessions()
        
        // Update existing session or add new one
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session
        } else {
            sessions.append(session)
        }
        
        // Sort by creation date (newest first)
        sessions.sort { $0.createdAt > $1.createdAt }
        
        saveBaseballKubbSessions(sessions)
    }
    
    func loadBaseballKubbSessions() -> [BaseballKubbSession] {
        guard let data = userDefaults.data(forKey: "BaseballKubbSessions") else {
            return []
        }
        
        do {
            let sessions = try JSONDecoder().decode([BaseballKubbSession].self, from: data)
            return sessions
        } catch {
            print("Error loading Baseball Kubb sessions from local storage: \(error)")
            return []
        }
    }
    
    func loadLastBaseballKubbSession() -> BaseballKubbSession? {
        let sessions = loadBaseballKubbSessions()
        return sessions.first
    }
    
    func loadIncompleteBaseballKubbSession() -> BaseballKubbSession? {
        let sessions = loadBaseballKubbSessions()
        let incompleteSessions = sessions.filter { !$0.isComplete }
        print("📱 Found \(incompleteSessions.count) incomplete Baseball Kubb sessions out of \(sessions.count) total")
        return incompleteSessions.first
    }
    
    private func saveBaseballKubbSessions(_ sessions: [BaseballKubbSession]) {
        do {
            let data = try JSONEncoder().encode(sessions)
            userDefaults.set(data, forKey: "BaseballKubbSessions")
        } catch {
            print("Error saving Baseball Kubb sessions to local storage: \(error)")
        }
    }
    
    func importData(_ data: Data) -> Bool {
        do {
            let sessions = try JSONDecoder().decode([PracticeSession].self, from: data)
            saveSessions(sessions)
            return true
        } catch {
            print("Error importing data: \(error)")
            return false
        }
    }
    
    // MARK: - Bulk Save Methods for Sync
    
    func savePracticeSessions(_ sessions: [PracticeSession]) {
        saveSessions(sessions)
    }
    
    func saveInkastBlastSessions(_ sessions: [InkastBlastSessionData]) {
        do {
            let data = try JSONEncoder().encode(sessions)
            userDefaults.set(data, forKey: "InkastBlastSessions")
        } catch {
            print("Error saving Inkast Blast sessions to local storage: \(error)")
        }
    }
    
    func saveBaseballKubbSessionsBulk(_ sessions: [BaseballKubbSession]) {
        saveBaseballKubbSessions(sessions)
    }
    
    func loadInkastBlastSessions() -> [InkastBlastSessionData] {
        guard let data = userDefaults.data(forKey: "InkastBlastSessions") else {
            return []
        }
        
        do {
            let sessions = try JSONDecoder().decode([InkastBlastSessionData].self, from: data)
            return sessions
        } catch {
            print("Error loading Inkast Blast sessions from local storage: \(error)")
            return []
        }
    }
    
    // MARK: - Full Game Sim Sessions
    
    func saveFullGameSimSession(_ session: FullGameSimSessionStruct) {
        var sessions = loadFullGameSimSessions()
        
        print("💾 LocalStorage: Saving Full Game Sim session \(session.id)")
        print("   - Current storage has \(sessions.count) sessions")
        
        // Update existing session or add new one
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            print("   - Updating existing session at index \(index)")
            sessions[index] = session
        } else {
            print("   - Adding new session")
            sessions.append(session)
        }
        
        // Deduplicate before saving (safety measure)
        let deduplicated = deduplicateFullGameSimSessions(sessions)
        if deduplicated.count != sessions.count {
            print("   ⚠️ Removed \(sessions.count - deduplicated.count) duplicates during save")
        }
        
        saveFullGameSimSessions(deduplicated)
        print("   ✅ Saved \(deduplicated.count) sessions to local storage")
    }
    
    private func deduplicateFullGameSimSessions(_ sessions: [FullGameSimSessionStruct]) -> [FullGameSimSessionStruct] {
        let grouped = Dictionary(grouping: sessions) { $0.id }
        
        return grouped.map { (_, sessionGroup) in
            // If multiple sessions with same ID, keep the one with highest round number
            // or most recent modifiedAt if rounds are equal
            sessionGroup.max { s1, s2 in
                if s1.currentRound != s2.currentRound {
                    return s1.currentRound < s2.currentRound
                }
                return s1.modifiedAt < s2.modifiedAt
            } ?? sessionGroup[0]
        }
    }
    
    func saveFullGameSimSessions(_ sessions: [FullGameSimSessionStruct]) {
        do {
            let data = try JSONEncoder().encode(sessions)
            userDefaults.set(data, forKey: "FullGameSimSessions")
        } catch {
            print("Error saving Full Game Sim sessions to local storage: \(error)")
        }
    }
    
    func deleteFullGameSimSession(_ session: FullGameSimSessionStruct) {
        var sessions = loadFullGameSimSessions()
        sessions.removeAll { $0.id == session.id }
        saveFullGameSimSessions(sessions)
    }
    
    func loadFullGameSimSessions() -> [FullGameSimSessionStruct] {
        guard let data = userDefaults.data(forKey: "FullGameSimSessions") else {
            return []
        }
        
        do {
            let sessions = try JSONDecoder().decode([FullGameSimSessionStruct].self, from: data)
            return sessions
        } catch {
            print("Error loading Full Game Sim sessions from local storage: \(error)")
            return []
        }
    }
}
