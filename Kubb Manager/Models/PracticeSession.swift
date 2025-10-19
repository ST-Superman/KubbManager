//
//  PracticeSession.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 9/23/25.
//

import Foundation
import CloudKit

// MARK: - Practice Session Data Model
// This struct represents a single practice session where a user practices kubb throwing
// It tracks progress, rounds, and integrates with CloudKit for data synchronization

struct PracticeSession: Identifiable, Codable, Equatable {
    // MARK: - Core Properties
    let id: String          // Unique identifier for this session
    let date: Date          // Date when the session was created
    var target: Int         // Target number of batons to throw (user's goal)
    var totalKubbs: Int     // Total kubb pieces knocked down in this session
    var totalBatons: Int    // Total batons thrown in this session
    var startTime: Date     // When the session actually started
    var endTime: Date?      // When the session ended (nil if still in progress)
    var isComplete: Bool    // Whether the session has been completed
    var isPaused: Bool      // Whether the session is currently paused
    var rounds: [Round]     // Array of rounds within this session
    let createdAt: Date     // When this session record was created
    var modifiedAt: Date    // When this session was last modified (for sync purposes)
    
    // MARK: - Initialization
    
    /// Creates a new practice session with the specified parameters
    /// - Parameters:
    ///   - id: Unique identifier (auto-generated if not provided)
    ///   - date: Date for the session (defaults to current date)
    ///   - target: Target number of batons to throw
    ///   - startTime: When the session actually started (defaults to current time)
    init(id: String = UUID().uuidString, 
         date: Date = Date(), 
         target: Int, 
         startTime: Date = Date()) {
        // Validate and ensure unique ID format
        let validatedId = Self.validateAndGenerateUniqueId(id)
        
        // Initialize all properties with default values
        self.id = validatedId
        self.date = date
        self.target = target
        self.totalKubbs = 0           // Start with no kubb hits
        self.totalBatons = 0          // Start with no batons thrown
        self.startTime = startTime
        self.endTime = nil            // No end time initially
        self.isComplete = false       // Session starts incomplete
        self.isPaused = false         // Session starts active
        self.rounds = []              // Start with empty rounds array
        self.createdAt = Date()       // Record creation time
        self.modifiedAt = Date()      // Record modification time
        
        // Create the first round immediately when starting a new session
        // This ensures there's always a current round to throw into
        let firstRound = Round(roundNumber: 1)
        self.rounds.append(firstRound)
        
        // Log session creation for debugging
        print("🆔 Created new PracticeSession with ID: \(validatedId)")
        print("   - Date: \(date)")
        print("   - Target: \(target)")
        print("   - StartTime: \(startTime)")
        print("   - First round created: Round 1")
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
        return min(Double(totalBatons) / Double(target), 1.0)
    }
    
    var isTargetReached: Bool {
        return totalBatons >= target
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

    // MARK: - Clutch Performance (Pressure Situations)

    /// Throws made when 3-4 kubbs remain (pressure situations)
    var clutchThrows: [(throw: BatonThrow, kubbsRemaining: Int)] {
        var clutchThrowsList: [(throw: BatonThrow, kubbsRemaining: Int)] = []

        for round in rounds {
            var kubbsHitSoFar = 0

            for batonThrow in round.batonThrows where batonThrow.throwType == .kubb {
                let kubbsRemaining = 5 - kubbsHitSoFar

                // Count throws when 3-4 kubbs remain (pressure)
                if kubbsRemaining >= 3 && kubbsRemaining <= 4 {
                    clutchThrowsList.append((throw: batonThrow, kubbsRemaining: kubbsRemaining))
                }

                if batonThrow.isHit {
                    kubbsHitSoFar += 1
                }
            }
        }

        return clutchThrowsList
    }

    /// Accuracy in clutch situations (when 3-4 kubbs remain)
    var clutchAccuracy: Double {
        let clutchAttempts = clutchThrows
        guard !clutchAttempts.isEmpty else { return 0.0 }

        let clutchHits = clutchAttempts.filter { $0.throw.isHit }.count
        return Double(clutchHits) / Double(clutchAttempts.count)
    }

    /// Accuracy in non-clutch situations (when 5, 2, or 1 kubbs remain)
    var normalAccuracy: Double {
        var normalThrowsCount = 0
        var normalHitsCount = 0

        for round in rounds {
            var kubbsHitSoFar = 0

            for batonThrow in round.batonThrows where batonThrow.throwType == .kubb {
                let kubbsRemaining = 5 - kubbsHitSoFar

                // Count throws when NOT in clutch situation
                if kubbsRemaining < 3 || kubbsRemaining > 4 {
                    normalThrowsCount += 1
                    if batonThrow.isHit {
                        normalHitsCount += 1
                    }
                }

                if batonThrow.isHit {
                    kubbsHitSoFar += 1
                }
            }
        }

        guard normalThrowsCount > 0 else { return 0.0 }
        return Double(normalHitsCount) / Double(normalThrowsCount)
    }

    /// Ratio of clutch accuracy to normal accuracy (>1.0 means performs better under pressure)
    var clutchPerformanceRatio: Double {
        guard normalAccuracy > 0 else { return 1.0 }
        return clutchAccuracy / normalAccuracy
    }

    // MARK: - Streak Tracking

    /// Current hit streak in the session (consecutive successful throws)
    var currentHitStreak: Int {
        var streak = 0
        var maxStreak = 0

        for round in rounds.sorted(by: { $0.roundNumber < $1.roundNumber }) {
            for batonThrow in round.batonThrows where batonThrow.throwType == .kubb {
                if batonThrow.isHit {
                    streak += 1
                    maxStreak = max(maxStreak, streak)
                } else {
                    streak = 0
                }
            }
        }

        return streak // Return current active streak
    }

    /// Longest hit streak achieved in this session
    var longestHitStreakInSession: Int {
        var currentStreak = 0
        var maxStreak = 0

        for round in rounds.sorted(by: { $0.roundNumber < $1.roundNumber }) {
            for batonThrow in round.batonThrows where batonThrow.throwType == .kubb {
                if batonThrow.isHit {
                    currentStreak += 1
                    maxStreak = max(maxStreak, currentStreak)
                } else {
                    currentStreak = 0
                }
            }
        }

        return maxStreak
    }

    /// Number of perfect rounds (100% accuracy) in this session
    var perfectRoundsCount: Int {
        return rounds.filter { $0.accuracy == 1.0 && $0.isComplete }.count
    }

    /// Whether this session contains any perfect rounds
    var hasPerfectRound: Bool {
        return perfectRoundsCount > 0
    }

    // MARK: - Session Management
    
    mutating func addBatonResult(isHit: Bool) {
        // Don't add batons if the current round is complete - wait for user confirmation
        if let currentRound = currentRound, currentRound.isRoundComplete {
            return
        }
        
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
            // If currentRound is nil but rounds exist, it means the last round just completed
            // Don't create a new round - wait for user confirmation via startNextRound()
            // The first round is now created when the session starts, so this should never happen
            // unless a round just completed
        }
    }
    
    mutating func startNextRound() {
        // Create a new round when user confirms they're ready
        let newRound = Round(roundNumber: rounds.count + 1)
        rounds.append(newRound)
        modifiedAt = Date()
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
