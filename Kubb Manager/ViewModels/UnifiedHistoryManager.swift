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
    
    init() {
        Task {
            await loadAllSessions()
        }
    }
    
    func loadAllSessions() async {
        isLoading = true
        
        do {
            // Load all session types
            await historyManager.loadSessions()
            let practiceSessions = historyManager.sessions
            let inkastBlastSessions = await cloudKitManager.fetchInkastBlastSessions()
            let baseballKubbSessions = try await cloudKitManager.fetchBaseballKubbSessions()
            
            // Convert to unified sessions
            var allSessions: [UnifiedSession] = []
            
            // Add practice sessions
            for session in practiceSessions {
                allSessions.append(.practice(session))
            }
            
            // Add inkast & blast sessions
            for session in inkastBlastSessions {
                allSessions.append(.inkastBlast(session))
            }
            
            // Add baseball kubb sessions
            for session in baseballKubbSessions {
                allSessions.append(.baseballKubb(session))
            }
            
            // Sort by date (newest first)
            allSessions.sort { $0.date > $1.date }
            
            sessions = allSessions
            
        } catch {
            print("❌ Failed to load sessions: \(error)")
        }
        
        isLoading = false
    }
    
    func refreshSessions() async {
        await loadAllSessions()
    }
    
    func deleteSession(_ session: UnifiedSession) async {
        switch session {
        case .practice(let practiceSession):
            await historyManager.deleteSession(practiceSession)
        case .inkastBlast(let inkastBlastSession):
            await cloudKitManager.deleteInkastBlastSession(inkastBlastSession)
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
