//
//  HistoryManager.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 9/23/25.
//

import Foundation
import Combine

@MainActor
class HistoryManager: ObservableObject {
    @Published var sessions: [PracticeSession] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isRefreshing: Bool = false
    
    private let cloudKitManager = CloudKitManager.shared
    
    init() {
        Task {
            await loadSessions()
        }
    }
    
    // MARK: - Data Loading
    
    func loadSessions() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedSessions = try await cloudKitManager.fetchSessions()
            let autoCompletedSessions = fetchedSessions.map { $0.withAutoCompletion() }
            sessions = deduplicateSessions(autoCompletedSessions)
            
            // Save any auto-completed sessions back to storage
            // Only save sessions that were actually changed by auto-completion
            await saveAutoCompletedSessions(fetchedSessions, autoCompletedSessions)
            
            isLoading = false
        } catch {
            errorMessage = cloudKitManager.handleCloudKitError(error)
            isLoading = false
        }
    }
    
    func refreshSessions() async {
        isRefreshing = true
        errorMessage = nil
        
        do {
            let fetchedSessions = try await cloudKitManager.fetchSessions()
            let autoCompletedSessions = fetchedSessions.map { $0.withAutoCompletion() }
            sessions = deduplicateSessions(autoCompletedSessions)
            
            // Save any auto-completed sessions back to storage
            // Only save sessions that were actually changed by auto-completion
            await saveAutoCompletedSessions(fetchedSessions, autoCompletedSessions)
            
            isRefreshing = false
        } catch {
            errorMessage = cloudKitManager.handleCloudKitError(error)
            isRefreshing = false
        }
    }
    
    func deleteSession(_ session: PracticeSession) async {
        do {
            try await cloudKitManager.deleteSession(session)
            sessions.removeAll { $0.id == session.id }
        } catch {
            errorMessage = cloudKitManager.handleCloudKitError(error)
        }
    }
    
    // MARK: - Statistics
    
    var totalSessions: Int {
        return sessions.count
    }
    
    var totalKubbsKnocked: Int {
        return sessions.reduce(0) { $0 + $1.totalKubbs }
    }
    
    var totalBatonsThrown: Int {
        return sessions.reduce(0) { $0 + $1.totalBatons }
    }
    
    var overallAccuracy: Double {
        guard totalBatonsThrown > 0 else { return 0.0 }
        return Double(totalKubbsKnocked) / Double(totalBatonsThrown)
    }
    
    var averageSessionAccuracy: Double {
        guard !sessions.isEmpty else { return 0.0 }
        let totalAccuracy = sessions.reduce(0.0) { $0 + $1.accuracy }
        return totalAccuracy / Double(sessions.count)
    }
    
    var bestSessionAccuracy: Double {
        return sessions.map { $0.accuracy }.max() ?? 0.0
    }
    
    var averageKubbsPerSession: Double {
        guard !sessions.isEmpty else { return 0.0 }
        return Double(totalKubbsKnocked) / Double(sessions.count)
    }
    
    var averageBatonsPerSession: Double {
        guard !sessions.isEmpty else { return 0.0 }
        return Double(totalBatonsThrown) / Double(sessions.count)
    }
    
    var totalBaselineClears: Int {
        return sessions.reduce(0) { $0 + $1.totalBaselineClears }
    }
    
    var totalKingThrows: Int {
        return sessions.reduce(0) { $0 + $1.totalKingThrows }
    }
    
    var totalKingHits: Int {
        return sessions.reduce(0) { $0 + $1.totalKingHits }
    }
    
    var overallKingAccuracy: Double {
        guard totalKingThrows > 0 else { return 0.0 }
        return Double(totalKingHits) / Double(totalKingThrows)
    }
    
    // MARK: - Filtering and Sorting
    
    func sessionsForDate(_ date: Date) -> [PracticeSession] {
        let calendar = Calendar.current
        return sessions.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }
    
    func sessionsForWeek(containing date: Date) -> [PracticeSession] {
        let calendar = Calendar.current
        let weekInterval = calendar.dateInterval(of: .weekOfYear, for: date)
        
        guard let start = weekInterval?.start, let end = weekInterval?.end else {
            return []
        }
        
        return sessions.filter { $0.date >= start && $0.date < end }
    }
    
    func sessionsForMonth(containing date: Date) -> [PracticeSession] {
        let calendar = Calendar.current
        let monthInterval = calendar.dateInterval(of: .month, for: date)
        
        guard let start = monthInterval?.start, let end = monthInterval?.end else {
            return []
        }
        
        return sessions.filter { $0.date >= start && $0.date < end }
    }
    
    var sessionsByMonth: [String: [PracticeSession]] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        
        return Dictionary(grouping: sessions) { session in
            formatter.string(from: session.date)
        }
    }
    
    // MARK: - Data Export
    
    func exportSessionsAsJSON() -> String? {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            
            let data = try encoder.encode(sessions)
            return String(data: data, encoding: .utf8)
        } catch {
            print("Error encoding sessions: \(error)")
            return nil
        }
    }
    
    func exportSessionsAsCSV() -> String? {
        var csv = "Date,Target,Kubbs,Batons,Accuracy,Duration,Rounds,Baseline Clears,King Throws,King Accuracy\n"
        
        for session in sessions {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            
            let duration: String
            if let endTime = session.endTime {
                let interval = endTime.timeIntervalSince(session.startTime)
                let minutes = Int(interval) / 60
                let seconds = Int(interval) % 60
                duration = "\(minutes):\(String(format: "%02d", seconds))"
            } else {
                duration = "N/A"
            }
            
            csv += "\(dateFormatter.string(from: session.date)),"
            csv += "\(session.target),"
            csv += "\(session.totalKubbs),"
            csv += "\(session.totalBatons),"
            csv += "\(String(format: "%.2f", session.accuracy)),"
            csv += "\(duration),"
            csv += "\(session.completedRounds.count),"
            csv += "\(session.totalBaselineClears),"
            csv += "\(session.totalKingThrows),"
            csv += "\(String(format: "%.2f", session.kingAccuracy))\n"
        }
        
        return csv
    }
    
    // MARK: - Private Methods
    
    private func deduplicateSessions(_ sessions: [PracticeSession]) -> [PracticeSession] {
        // Group sessions by ID
        let groupedSessions = Dictionary(grouping: sessions) { $0.id }
        
        var deduplicatedSessions: [PracticeSession] = []
        var hasDuplicates = false
        
        for (sessionId, sessionGroup) in groupedSessions {
            if sessionGroup.count == 1 {
                // No duplicates, just add the session
                deduplicatedSessions.append(sessionGroup[0])
            } else {
                // Multiple sessions with same ID - need to determine which one to keep
                print("⚠️ Found \(sessionGroup.count) duplicate sessions with ID: \(sessionId)")
                hasDuplicates = true
                
                // Enhanced deduplication logic
                let keptSession = selectBestSession(from: sessionGroup)
                deduplicatedSessions.append(keptSession)
                
                print("✅ Kept session with modifiedAt: \(keptSession.modifiedAt), isComplete: \(keptSession.isComplete)")
                
                // Clean up CloudKit duplicates for this session ID
                Task {
                    await cleanupCloudKitDuplicates(for: sessionId, keepSession: keptSession)
                }
            }
        }
        
        // If we found duplicates, trigger an immediate CloudKit cleanup
        if hasDuplicates {
            print("🧹 Duplicates detected - triggering immediate CloudKit cleanup...")
            Task {
                await cloudKitManager.removeDuplicateCloudKitRecords()
            }
        }
        
        // Sort by date (newest first)
        deduplicatedSessions.sort { $0.date > $1.date }
        
        return deduplicatedSessions
    }
    
    /// Enhanced session selection logic to handle completed vs incomplete duplicates
    private func selectBestSession(from sessions: [PracticeSession]) -> PracticeSession {
        guard !sessions.isEmpty else { return sessions[0] }
        
        // First, check if any sessions are completed
        let completedSessions = sessions.filter { $0.isComplete }
        let incompleteSessions = sessions.filter { !$0.isComplete }
        
        if completedSessions.count == 1 && incompleteSessions.count == 1 {
            // Special case: one completed, one incomplete with same ID
            let completed = completedSessions[0]
            let incomplete = incompleteSessions[0]
            
            print("🔍 Found completed vs incomplete duplicate for session \(sessions[0].id)")
            print("   - Completed: modifiedAt=\(completed.modifiedAt), totalKubbs=\(completed.totalKubbs)")
            print("   - Incomplete: modifiedAt=\(incomplete.modifiedAt), totalKubbs=\(incomplete.totalKubbs)")
            
            // If the completed session is newer or same age, keep it
            if completed.modifiedAt >= incomplete.modifiedAt {
                print("✅ Keeping completed session (newer or same age)")
                return completed
            } else {
                // If incomplete is newer, but completed has more progress, keep completed
                if completed.totalKubbs > incomplete.totalKubbs {
                    print("✅ Keeping completed session (more progress despite being older)")
                    return completed
                } else {
                    print("⚠️ Keeping incomplete session (newer and same/less progress)")
                    return incomplete
                }
            }
        }
        
        // For all other cases, use the standard logic: most recent modifiedAt
        let sortedSessions = sessions.sorted { $0.modifiedAt > $1.modifiedAt }
        return sortedSessions[0]
    }
    
    private func cleanupCloudKitDuplicates(for sessionId: String, keepSession: PracticeSession) async {
        // Use the existing CloudKit cleanup function which handles the query properly
        await cloudKitManager.removeDuplicateCloudKitRecords()
        print("🧹 Triggered CloudKit duplicate cleanup for session \(sessionId)")
    }
    
    /// Saves any auto-completed sessions back to CloudKit and local storage
    /// Only saves sessions that were actually changed by auto-completion
    private func saveAutoCompletedSessions(_ originalSessions: [PracticeSession], _ autoCompletedSessions: [PracticeSession]) async {
        let calendar = Calendar.current
        
        // Find sessions that were actually changed by auto-completion
        var sessionsToSave: [PracticeSession] = []
        
        for (original, autoCompleted) in zip(originalSessions, autoCompletedSessions) {
            let isToday = calendar.isDateInToday(original.date)
            
            // Only consider sessions from previous days
            if !isToday {
                // Check if the session was actually modified by auto-completion
                let wasChanged = !original.isComplete && autoCompleted.isComplete
                
                if wasChanged {
                    sessionsToSave.append(autoCompleted)
                }
            }
        }
        
        if !sessionsToSave.isEmpty {
            print("🔄 Auto-completing \(sessionsToSave.count) sessions from previous days")
            
            for session in sessionsToSave {
                do {
                    // Save to CloudKit
                    try await cloudKitManager.saveSession(session)
                    print("✅ Auto-completed session \(session.id) saved to CloudKit")
                } catch {
                    print("❌ Failed to save auto-completed session \(session.id): \(error)")
                }
            }
        } else {
            print("⏭️ No sessions need auto-completion - all previous day sessions are already complete")
        }
    }
    
}
