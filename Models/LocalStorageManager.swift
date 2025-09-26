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
}
