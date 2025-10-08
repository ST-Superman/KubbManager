//
//  UnifiedHistoryManager.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 1/15/25.
//

import Foundation
import CloudKit

@MainActor
class UnifiedHistoryManager: ObservableObject {
    @Published var sessions: [UnifiedSession] = []
    @Published var isLoading = false
    
    private let historyManager = HistoryManager()
    private let cloudKitManager = CloudKitManager.shared
    private let localStorage = LocalStorageManager.shared
    
    init() {
        // Listen for refresh notifications
        NotificationCenter.default.addObserver(
            forName: .dataRefreshRequired,
            object: nil,
            queue: .main
        ) { _ in
            Task {
                await self.loadAllSessions()
            }
        }
        
        Task {
            await loadAllSessions()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func loadAllSessions() async {
        isLoading = true
        
        print("🔄 UnifiedHistoryManager: Loading all sessions from local storage...")
        
        // Load all session types from local storage (source of truth)
        let practiceSessions = localStorage.loadSessions()
        let inkastBlastSessions = localStorage.loadInkastBlastSessions()
        let fullGameSimSessions = localStorage.loadFullGameSimSessions()
        let baseballKubbSessions = localStorage.loadBaseballKubbSessions()
        
        print("📊 Local storage counts - Practice: \(practiceSessions.count), InkastBlast: \(inkastBlastSessions.count), FullGameSim: \(fullGameSimSessions.count), BaseballKubb: \(baseballKubbSessions.count)")
        
        // Convert to unified sessions
        var allSessions: [UnifiedSession] = []
        
        // Add practice sessions
        for session in practiceSessions {
            print("📝 Adding practice session: \(session.id)")
            allSessions.append(.practice(session))
        }
        
        // Add inkast & blast sessions
        for session in inkastBlastSessions {
            print("⚡ Adding inkast blast session: \(session.id) (complete: \(session.isComplete))")
            allSessions.append(.inkastBlast(session))
        }
        
        // Add full game sim sessions
        for session in fullGameSimSessions {
            print("🎯 Adding full game sim session: \(session.id) (complete: \(session.isComplete))")
            allSessions.append(.fullGameSim(session))
        }
        
        // Add baseball kubb sessions
        for session in baseballKubbSessions {
            print("⚾ Adding baseball kubb session: \(session.id)")
            allSessions.append(.baseballKubb(session))
        }
        
        // Deduplicate sessions by ID
        sessions = deduplicateSessions(allSessions)
        
        // Sort by date (newest first)
        sessions.sort { $0.date > $1.date }
        
        print("✅ UnifiedHistoryManager: Loaded \(sessions.count) total sessions")
        
        isLoading = false
    }
    
    func refreshSessions() async {
        await loadAllSessions()
    }
    
    // MARK: - Private Methods
    
    private func deduplicateSessions(_ sessions: [UnifiedSession]) -> [UnifiedSession] {
        // Group sessions by type and appropriate key for deduplication
        var groupedSessions: [String: [UnifiedSession]] = [:]
        
        for session in sessions {
            let groupKey: String
            switch session {
            case .practice(let practiceSession):
                groupKey = "\(session.sessionType.rawValue)-\(practiceSession.id)"
            case .inkastBlast(let inkastSession):
                // For Inkast & Blast, group by sessionId AND gamePhase
                groupKey = "\(session.sessionType.rawValue)-\(inkastSession.id)-\(inkastSession.gamePhase.rawValue)"
            case .fullGameSim(let fullGameSimSession):
                groupKey = "\(session.sessionType.rawValue)-\(fullGameSimSession.id)"
            case .baseballKubb(let baseballSession):
                groupKey = "\(session.sessionType.rawValue)-\(baseballSession.id)"
            }
            
            if groupedSessions[groupKey] == nil {
                groupedSessions[groupKey] = []
            }
            groupedSessions[groupKey]?.append(session)
        }
        
        var deduplicatedSessions: [UnifiedSession] = []
        var hasDuplicates = false
        
        for (groupKey, sessionGroup) in groupedSessions {
            if sessionGroup.count == 1 {
                // No duplicates, just add the session
                deduplicatedSessions.append(sessionGroup[0])
            } else {
                // Multiple sessions with same group key - need to determine which one to keep
                print("⚠️ Found \(sessionGroup.count) duplicate sessions for group: \(groupKey)")
                hasDuplicates = true
                
                // Log details about each duplicate
                for (index, session) in sessionGroup.enumerated() {
                    print("   Duplicate \(index + 1): date=\(session.date), type=\(session.sessionType.rawValue)")
                }
                
                // Choose the best session based on type-specific logic
                let keptSession = selectBestSession(from: sessionGroup)
                deduplicatedSessions.append(keptSession)
                
                print("✅ Kept session with date: \(keptSession.date), type: \(keptSession.sessionType.rawValue)")
            }
        }
        
        if hasDuplicates {
            print("🧹 UnifiedHistoryManager: Removed duplicate sessions within same type")
        }
        
        return deduplicatedSessions
    }
    
    private func selectBestSession(from sessions: [UnifiedSession]) -> UnifiedSession {
        guard !sessions.isEmpty else { return sessions[0] }
        
        // If all sessions are the same type, use type-specific logic
        let sessionType = sessions[0].sessionType
        if sessions.allSatisfy({ $0.sessionType == sessionType }) {
            switch sessionType {
            case .inkastBlast:
                return selectBestInkastBlastSession(from: sessions)
            case .practice, .fullGameSim, .baseballKubb:
                // For practice, full game sim, and baseball kubb, use most recent date
                return sessions.max { $0.date < $1.date } ?? sessions[0]
            }
        }
        
        // Mixed types - use most recent date
        return sessions.max { $0.date < $1.date } ?? sessions[0]
    }
    
    private func selectBestInkastBlastSession(from sessions: [UnifiedSession]) -> UnifiedSession {
        // Extract InkastBlastSessionData from UnifiedSession
        let inkastSessions = sessions.compactMap { session in
            if case .inkastBlast(let inkastSession) = session {
                return inkastSession
            }
            return nil
        }
        
        guard !inkastSessions.isEmpty else { return sessions[0] }
        
        // Find the best session: max totalRounds, then latest createdAt
        let bestSession = inkastSessions.max { session1, session2 in
            if session1.totalRounds != session2.totalRounds {
                return session1.totalRounds < session2.totalRounds
            }
            return session1.createdAt < session2.createdAt
        }
        
        // Convert back to UnifiedSession
        if let bestSession = bestSession {
            return .inkastBlast(bestSession)
        }
        
        return sessions[0]
    }
    
    func deleteSession(_ session: UnifiedSession) async {
        switch session {
        case .practice(let practiceSession):
            await historyManager.deleteSession(practiceSession)
        case .inkastBlast(let inkastBlastSession):
            await cloudKitManager.deleteInkastBlastSession(inkastBlastSession)
        case .fullGameSim(let fullGameSimSession):
            await cloudKitManager.deleteFullGameSimSession(fullGameSimSession)
        case .baseballKubb(let baseballKubbSession):
            await cloudKitManager.deleteBaseballKubbSession(baseballKubbSession)
        }
        
        await loadAllSessions()
    }
    
    // Statistics
    var totalSessions: Int {
        sessions.count
    }
    
    var totalPracticeSessions: Int {
        sessions.filter { 
            if case .practice = $0 { return true }
            return false
        }.count
    }
    
    var totalInkastBlastSessions: Int {
        sessions.filter { 
            if case .inkastBlast = $0 { return true }
            return false
        }.count
    }
    
    var totalFullGameSimSessions: Int {
        sessions.filter { 
            if case .fullGameSim = $0 { return true }
            return false
        }.count
    }
    
    var totalBaseballKubbSessions: Int {
        sessions.filter { 
            if case .baseballKubb = $0 { return true }
            return false
        }.count
    }
    
    var totalTimeSpent: TimeInterval {
        sessions.compactMap { $0.duration }.reduce(0, +)
    }
    
    var totalKubbsKnocked: Int {
        sessions.reduce(0) { total, session in
            switch session {
            case .practice(let practiceSession):
                return total + practiceSession.totalKubbs
            case .inkastBlast(let inkastBlastSession):
                return total + inkastBlastSession.totalInkastKubbs
            case .fullGameSim(let fullGameSimSession):
                return total + fullGameSimSession.totalKubbsKnockedDown
            case .baseballKubb(let baseballKubbSession):
                return total + baseballKubbSession.userScore
            }
        }
    }
    
    var overallAccuracy: Double {
        let sessionsWithAccuracy = sessions.compactMap { $0.accuracy }
        guard !sessionsWithAccuracy.isEmpty else { return 0.0 }
        return sessionsWithAccuracy.reduce(0, +) / Double(sessionsWithAccuracy.count)
    }
}
