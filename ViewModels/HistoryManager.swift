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
            sessions = deduplicateSessions(fetchedSessions)
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
            sessions = deduplicateSessions(fetchedSessions)
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
        
        for (_, sessionGroup) in groupedSessions {
            if sessionGroup.count == 1 {
                // No duplicates, just add the session
                deduplicatedSessions.append(sessionGroup[0])
            } else {
                // Multiple sessions with same ID - keep the most recent one
                print("⚠️ Found \(sessionGroup.count) duplicate sessions with ID: \(sessionGroup[0].id)")
                
                // Sort by modifiedAt date (newest first) and take the first one
                let sortedSessions = sessionGroup.sorted { $0.modifiedAt > $1.modifiedAt }
                deduplicatedSessions.append(sortedSessions[0])
                
                print("✅ Kept session with modifiedAt: \(sortedSessions[0].modifiedAt)")
            }
        }
        
        // Sort by date (newest first)
        deduplicatedSessions.sort { $0.date > $1.date }
        
        return deduplicatedSessions
    }
}
