//
//  LocalStorageManager.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 9/23/25.
//

import Foundation

@MainActor
class LocalStorageManager: ObservableObject {
    static let shared = LocalStorageManager()
    
    private let userDefaults = UserDefaults.standard
    private let sessionsKey = "PracticeSessions"
    
    private init() {}
    
    // MARK: - Session Operations
    
    func saveSession(_ session: PracticeSession) {
        var sessions = loadSessions()
        
        // Update existing session or add new one
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session
        } else {
            sessions.append(session)
        }
        
        // Sort by creation date (newest first)
        sessions.sort { $0.createdAt > $1.createdAt }
        
        saveSessions(sessions)
    }
    
    func loadSessions() -> [PracticeSession] {
        guard let data = userDefaults.data(forKey: sessionsKey) else {
            return []
        }
        
        do {
            let sessions = try JSONDecoder().decode([PracticeSession].self, from: data)
            return sessions
        } catch {
            print("Error loading sessions from local storage: \(error)")
            return []
        }
    }
    
    func fetchIncompleteSession() -> PracticeSession? {
        let sessions = loadSessions()
        print("🔍 Checking for incomplete sessions...")
        print("Total sessions: \(sessions.count)")
        
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
