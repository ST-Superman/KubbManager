//
//  PracticeSession.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 9/23/25.
//

import Foundation
import CloudKit

struct PracticeSession: Identifiable, Codable, Equatable {
    let id: String
    let date: Date
    var target: Int
    var totalKubbs: Int
    var totalBatons: Int
    var startTime: Date
    var endTime: Date?
    var isComplete: Bool
    var isPaused: Bool
    var rounds: [Round]
    let createdAt: Date
    var modifiedAt: Date
    
    init(id: String = UUID().uuidString, 
         date: Date = Date(), 
         target: Int, 
         startTime: Date = Date()) {
        // Validate and ensure unique ID
        let validatedId = Self.validateAndGenerateUniqueId(id)
        
        self.id = validatedId
        self.date = date
        self.target = target
        self.totalKubbs = 0
        self.totalBatons = 0
        self.startTime = startTime
        self.endTime = nil
        self.isComplete = false
        self.isPaused = false
        self.rounds = []
        self.createdAt = Date()
        self.modifiedAt = Date()
        
        print("🆔 Created new PracticeSession with ID: \(validatedId)")
        print("   - Date: \(date)")
        print("   - Target: \(target)")
        print("   - StartTime: \(startTime)")
    }
    
    // Internal initializer for CloudKit reconstruction and conversions (no logging)
    init(id: String,
                 date: Date,
                 target: Int,
                 totalKubbs: Int,
                 totalBatons: Int,
                 startTime: Date,
                 endTime: Date?,
                 isComplete: Bool,
                 isPaused: Bool,
                 rounds: [Round],
                 createdAt: Date,
                 modifiedAt: Date) {
        self.id = id
        self.date = date
        self.target = target
        self.totalKubbs = totalKubbs
        self.totalBatons = totalBatons
        self.startTime = startTime
        self.endTime = endTime
        self.isComplete = isComplete
        self.isPaused = isPaused
        self.rounds = rounds
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
    
    // MARK: - ID Validation
    
    private static func validateAndGenerateUniqueId(_ providedId: String) -> String {
        // Check if the provided ID is valid UUID format
        if UUID(uuidString: providedId) != nil {
            print("✅ Using provided valid UUID: \(providedId)")
            return providedId
        } else {
            let newId = UUID().uuidString
            print("⚠️ Invalid UUID provided (\(providedId)), generated new UUID: \(newId)")
            return newId
        }
    }
    
    // MARK: - CloudKit Integration
    
    static let recordType = "Practice_Session"
    
    init?(from record: CKRecord) {
        guard let id = record["sessionId"] as? String,
              let date = record["date"] as? Date,
              let target = record["target"] as? Int64,
              let totalKubbs = record["totalKubbs"] as? Int64,
              let totalBatons = record["totalBatons"] as? Int64,
              let startTime = record["startTime"] as? Date,
              let isComplete = record["isComplete"] as? Int64,
              let createdAt = record["createdAt"] as? Date,
              let modifiedAt = record["modifiedAt"] as? Date else {
            return nil
        }
        
        // Use private initializer to avoid logging for CloudKit reconstruction
        self.init(
            id: id,
            date: date,
            target: Int(target),
            totalKubbs: Int(totalKubbs),
            totalBatons: Int(totalBatons),
            startTime: startTime,
            endTime: record["endTime"] as? Date,
            isComplete: isComplete == 1,
            isPaused: (record["isPaused"] as? Int64 ?? 0) == 1,
            rounds: [],
            createdAt: createdAt,
            modifiedAt: modifiedAt
        )
        
        // Parse rounds from JSON string
        if let roundsData = record["rounds"] as? String,
           let roundsJSON = roundsData.data(using: .utf8) {
            self.rounds = (try? JSONDecoder().decode([Round].self, from: roundsJSON)) ?? []
        }
    }
    
    func toCKRecord() -> CKRecord {
        // Let CloudKit generate the record ID automatically to avoid queryable field issues
        let record = CKRecord(recordType: Self.recordType)
        
        // Store our custom ID as a regular field instead of using it as recordName
        record["sessionId"] = id
        record["date"] = date
        record["target"] = Int64(target)
        record["totalKubbs"] = Int64(totalKubbs)
        record["totalBatons"] = Int64(totalBatons)
        record["startTime"] = startTime
        record["endTime"] = endTime
        record["isComplete"] = isComplete ? 1 : 0
        record["isPaused"] = isPaused ? 1 : 0
        record["createdAt"] = createdAt
        record["modifiedAt"] = modifiedAt
        
        // Store rounds as JSON string
        if let roundsData = try? JSONEncoder().encode(rounds),
           let roundsString = String(data: roundsData, encoding: .utf8) {
            record["rounds"] = roundsString
        }
        
        return record
    }
    
    // MARK: - Computed Properties
    
    var accuracy: Double {
        guard totalBatons > 0 else { return 0.0 }
        return Double(totalKubbs) / Double(totalBatons)
    }
    
    var progressPercentage: Double {
        guard target > 0 else { return 0.0 }
        return min(Double(totalKubbs) / Double(target), 1.0)
    }
    
    var isTargetReached: Bool {
        return totalKubbs >= target
    }
    
    var isIncomplete: Bool {
        // A session is incomplete ONLY if it's from today and either paused or hasn't reached the target
        // Sessions from previous days are automatically considered complete (even if target not reached)
        let calendar = Calendar.current
        let isToday = calendar.isDateInToday(date)
        return isToday && (isPaused || !isTargetReached)
    }
    
    /// Returns a session with auto-completion applied for previous days
    /// Sessions from previous days are automatically marked as complete
    func withAutoCompletion() -> PracticeSession {
        let calendar = Calendar.current
        let isToday = calendar.isDateInToday(date)
        
        // If it's not from today and not already complete, mark it as complete
        if !isToday && !isComplete {
            var autoCompletedSession = self
            autoCompletedSession.isComplete = true
            autoCompletedSession.isPaused = false
            autoCompletedSession.endTime = endTime ?? Date()
            // DON'T update modifiedAt here - this prevents circular sync loops
            // The modifiedAt should only be updated when the session is actually modified by the user
            return autoCompletedSession
        }
        
        return self
    }
    
    var currentRound: Round? {
        rounds.first { !$0.isComplete }
    }
    
    var completedRounds: [Round] {
        return rounds.filter { $0.isComplete }
    }
    
    var totalBaselineClears: Int {
        return rounds.filter { $0.hasBaselineClear }.count
    }
    
    var totalKingThrows: Int {
        return rounds.reduce(0) { $0 + $1.kingThrowsCount }
    }
    
    var totalKingHits: Int {
        return rounds.reduce(0) { $0 + $1.kingHits }
    }
    
    var totalKingThrowAttempts: Int {
        return rounds.reduce(0) { $0 + $1.kingThrowAttempts }
    }
    
    var kingAccuracy: Double {
        guard totalKingThrowAttempts > 0 else { return 0.0 }
        return Double(totalKingHits) / Double(totalKingThrowAttempts)
    }
    
    // MARK: - Session Management
    
    mutating func addBatonResult(isHit: Bool) {
        totalBatons += 1
        
        if isHit {
            totalKubbs += 1
        }
        
        modifiedAt = Date()
        
        // Update current round or create new one
        if let currentRound = currentRound {
            let index = rounds.firstIndex { $0.id == currentRound.id }!
            
            // Determine throw type based on current round state
            let throwType: BatonThrow.ThrowType
            if currentRound.hits >= 5 && currentRound.totalBatonThrows == 5 {
                // This is the 6th throw and we have 5 hits - it's a king throw
                throwType = .king
            } else {
                // Regular kubb throw
                throwType = .kubb
            }
            
            rounds[index].addBatonThrow(isHit: isHit, throwType: throwType)
        } else {
            let newRound = Round(roundNumber: rounds.count + 1)
            rounds.append(newRound)
            let index = rounds.count - 1
            rounds[index].addBatonThrow(isHit: isHit, throwType: .kubb)
        }
    }
    
    mutating func completeSession() {
        // Mark as complete when user explicitly ends the session
        // This ensures the session appears in history regardless of whether target was reached
        isComplete = true
        isPaused = false
        endTime = Date()
        modifiedAt = Date()
    }
    
    mutating func pauseSession() {
        // Pause the session so it can be resumed later
        isPaused = true
        modifiedAt = Date()
    }
    
    mutating func resumeSession() {
        // Resume a paused session
        isPaused = false
        modifiedAt = Date()
    }
    
    mutating func endSessionEarly() {
        // End session without marking as complete (for early exits)
        // This allows the session to be resumed later if it's from today
        endTime = Date()
        modifiedAt = Date()
        // Note: isComplete remains false, allowing it to be detected as incomplete
    }
    
    mutating func resetCurrentRound() {
        guard let currentRound = currentRound else { return }
        let index = rounds.firstIndex { $0.id == currentRound.id }!
        rounds[index] = Round(roundNumber: currentRound.roundNumber)
    }
}
