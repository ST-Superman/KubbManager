//
//  BaseballKubbSession.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 9/23/25.
//

import Foundation
import CloudKit

// MARK: - User Team Selection
// This enum defines which team the user is playing for in a Baseball Kubb game
enum UserTeam: String, CaseIterable, Codable {
    case away = "away"  // User plays for the away team
    case home = "home"  // User plays for the home team
    case both = "both"  // User practices with both teams (training mode)
    case none = "none"  // User is just keeping score (scorekeeper mode)
    
    /// Human-readable display name for the user team selection
    var displayName: String {
        switch self {
        case .away:
            return "Away Team"
        case .home:
            return "Home Team"
        case .both:
            return "Both Teams (Practice)"
        case .none:
            return "None (Scorekeeper)"
        }
    }
}

// MARK: - Baseball Kubb Session Data Model
// This struct represents a complete Baseball Kubb game session
// It combines traditional kubb rules with baseball-style innings and scoring

struct BaseballKubbSession: Identifiable, Codable {
    // MARK: - Basic Properties
    let id: String              // Unique identifier for this game session
    let date: Date              // Date when the game was played
    var awayTeam: String        // Name of the away team
    var homeTeam: String        // Name of the home team
    var userTeam: UserTeam      // Which team the user is playing for
    
    // MARK: - Game State Properties
    var currentInning: Int      // Current inning number (1-9+)
    var isTop: Bool             // true = top half (away team), false = bottom half (home team)
    var gameOver: Bool          // Whether the game has ended
    var winner: String?         // Winning team name (nil if game not over)
    var isComplete: Bool        // Whether the game session is complete
    
    // MARK: - Score Tracking
    var awayScore: Int          // Away team's total runs
    var homeScore: Int          // Home team's total runs
    var awayKings: Int          // Away team's total kings
    var homeKings: Int          // Home team's total kings
    
    // MARK: - Current Half-Inning State
    var fieldKubbs: Int                    // Kubbs currently on the field
    var fieldKubbsAtStartOfHalf: Int      // Field kubbs at start of current half-inning
    var awayBaselineKubbs: Int            // Away team's baseline kubbs
    var homeBaselineKubbs: Int            // Home team's baseline kubbs
    var batonCount: Int                   // Batons thrown in current half-inning
    var missCount: Int                    // Misses in current half-inning
    var halfInningRuns: Int               // Runs scored in current half-inning
    var halfInningKings: Int              // Kings hit in current half-inning
    var runsAfterKingHit: Int             // Runs scored after a king hit (for field kubb calculation)
    var kingThrowAttempts: Int            // Total king throw attempts in game
    var firstThrowKubbsHit: Int           // Kubbs hit on first throw of half-inning
    
    // MARK: - History and Undo Support
    var throwHistory: [BaseballKubbThrowState]        // State after each throw (for undo)
    var halfInningHistory: [BaseballKubbHalfInningState] // State at start of each half-inning
    var scoreboardHistory: [BaseballKubbScoreboardEntry] // Scoreboard data for each half-inning
    
    // MARK: - Metadata
    let createdAt: Date         // When this session was created
    var modifiedAt: Date        // When this session was last modified
    
    init(id: String = UUID().uuidString, date: Date = Date(), awayTeam: String = "", homeTeam: String = "", userTeam: UserTeam = .away) {
        self.id = id
        self.date = date
        self.awayTeam = awayTeam
        self.homeTeam = homeTeam
        self.userTeam = userTeam
        self.currentInning = 1
        self.isTop = true
        self.awayScore = 0
        self.homeScore = 0
        self.awayKings = 0
        self.homeKings = 0
        self.fieldKubbs = 0
        self.fieldKubbsAtStartOfHalf = 0
        self.awayBaselineKubbs = 5
        self.homeBaselineKubbs = 5
        self.batonCount = 0
        self.missCount = 0
        self.halfInningRuns = 0
        self.halfInningKings = 0
        self.runsAfterKingHit = 0
        self.kingThrowAttempts = 0
        self.firstThrowKubbsHit = 0
        self.gameOver = false
        self.winner = nil
        self.throwHistory = []
        self.halfInningHistory = []
        self.scoreboardHistory = []
        self.isComplete = false
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
    
    // MARK: - Computed Properties
    
    var currentTeam: String {
        return isTop ? awayTeam : homeTeam
    }
    
    var currentBaselineKubbs: Int {
        return isTop ? awayBaselineKubbs : homeBaselineKubbs
    }
    
    // MARK: - User Team Statistics
    
    var userScore: Int {
        switch userTeam {
        case .away:
            return awayScore
        case .home:
            return homeScore
        case .both:
            return awayScore + homeScore
        case .none:
            return 0 // No personal score tracking for scorekeeper
        }
    }
    
    var userKings: Int {
        switch userTeam {
        case .away:
            return awayKings
        case .home:
            return homeKings
        case .both:
            return awayKings + homeKings
        case .none:
            return 0 // No personal king tracking for scorekeeper
        }
    }
    
    var userBaselineKubbs: Int {
        switch userTeam {
        case .away:
            return awayBaselineKubbs
        case .home:
            return homeBaselineKubbs
        case .both:
            return awayBaselineKubbs + homeBaselineKubbs
        case .none:
            return 0 // No personal baseline kubb tracking for scorekeeper
        }
    }
    
    var isUserTeamAtBat: Bool {
        switch userTeam {
        case .away:
            return isTop
        case .home:
            return !isTop
        case .both:
            return true // Always true when playing both teams
        case .none:
            return true // Scorekeeper can track any team's at-bat
        }
    }
    
    // MARK: - Scoreboard Data
    
    var scoreboardData: [(awayRuns: Int, awayKings: Int, homeRuns: Int, homeKings: Int)] {
        var data: [(awayRuns: Int, awayKings: Int, homeRuns: Int, homeKings: Int)] = []
        
        // Process scoreboard history first (most reliable)
        for entry in scoreboardHistory {
            let targetIndex = (entry.inning - 1) * 2 + (entry.isTop ? 0 : 1)
            
            // Ensure we have enough entries in the array
            while data.count <= targetIndex {
                data.append((awayRuns: 0, awayKings: 0, homeRuns: 0, homeKings: 0))
            }
            
            data[targetIndex] = (awayRuns: entry.awayRuns, awayKings: entry.awayKings, homeRuns: entry.homeRuns, homeKings: entry.homeKings)
        }
        
        // Add current half-inning data if it has been completed
        if isHalfInningOver {
            let targetIndex = (currentInning - 1) * 2 + (isTop ? 0 : 1)
            
            // Ensure we have enough entries in the array
            while data.count <= targetIndex {
                data.append((awayRuns: 0, awayKings: 0, homeRuns: 0, homeKings: 0))
            }
            
            if isTop {
                // Top half - away team scored
                data[targetIndex] = (awayRuns: halfInningRuns, awayKings: halfInningKings, homeRuns: 0, homeKings: 0)
            } else {
                // Bottom half - home team scored
                data[targetIndex] = (awayRuns: 0, awayKings: 0, homeRuns: halfInningRuns, homeKings: halfInningKings)
            }
        }
        
        return data
    }
    
    var batonLimit: Int {
        return currentInning == 9 ? 999 : 6
    }
    
    var isHalfInningOver: Bool {
        // Always end on 3 misses
        if missCount >= 3 {
            return true
        }
        
        // For innings 1-8, end after 6 batons
        if currentInning < 9 && batonCount >= batonLimit {
            return true
        }
        
        // For bottom of 9th inning, also end if home team has a lead (walk-off)
        if currentInning == 9 && !isTop && homeScore > awayScore {
            return true
        }
        
        return false
    }
    
    var currentBaton: Int {
        return batonCount + 1
    }
    
    // MARK: - Game Management
    
    mutating func recordHit(fieldKubbsHit: Int, baselineKubbsHit: Int, kingHit: Bool) {
        saveThrowState()
        
        batonCount += 1
        
        // Update field kubbs
        fieldKubbs -= fieldKubbsHit
        
        // Update baseline kubbs and score
        if isTop {
            awayBaselineKubbs -= baselineKubbsHit
            awayScore += baselineKubbsHit
        } else {
            homeBaselineKubbs -= baselineKubbsHit
            homeScore += baselineKubbsHit
        }
        
        halfInningRuns += baselineKubbsHit
        
        // Handle king hit
        if kingHit {
            if isTop {
                awayScore += 1
                awayKings += 1
            } else {
                homeScore += 1
                homeKings += 1
            }
            
            halfInningRuns += 1
            halfInningKings += 1
            
            // Reset pitch
            resetPitch()
            
            // Reset tracking for field kubb calculation
            fieldKubbsAtStartOfHalf = 0
            runsAfterKingHit = 0
        } else if halfInningKings > 0 {
            // If king was hit earlier this half, track kubbs hit after the reset
            runsAfterKingHit += baselineKubbsHit
        }
        
        modifiedAt = Date()
    }
    
    mutating func recordMiss() {
        saveThrowState()
        
        batonCount += 1
        missCount += 1
        
        modifiedAt = Date()
    }
    
    mutating func resetPitch() {
        fieldKubbs = 0
        awayBaselineKubbs = 5
        homeBaselineKubbs = 5
    }
    
    mutating func nextHalf() {
        saveHalfInningState()
        
        // Save current half-inning to scoreboard history
        let scoreboardEntry = BaseballKubbScoreboardEntry(
            inning: currentInning,
            isTop: isTop,
            awayRuns: isTop ? halfInningRuns : 0,
            awayKings: isTop ? halfInningKings : 0,
            homeRuns: isTop ? 0 : halfInningRuns,
            homeKings: isTop ? 0 : halfInningKings
        )
        scoreboardHistory.append(scoreboardEntry)
        
        // Calculate field kubbs for next half
        let kubbsForFieldKubbs: Int
        
        if halfInningKings > 0 {
            // King was hit this half - only kubbs hit AFTER the king reset count
            kubbsForFieldKubbs = runsAfterKingHit
        } else {
            // No king hit - normal calculation: field kubbs cleared + baseline kubbs hit
            let fieldKubbsCleared = fieldKubbsAtStartOfHalf - fieldKubbs
            kubbsForFieldKubbs = fieldKubbsCleared + halfInningRuns
        }
        
        if isTop {
            // Moving to bottom half
            isTop = false
            fieldKubbs = kubbsForFieldKubbs
            fieldKubbsAtStartOfHalf = kubbsForFieldKubbs
        } else {
            // Moving to next inning
            currentInning += 1
            isTop = true
            fieldKubbs = kubbsForFieldKubbs
            fieldKubbsAtStartOfHalf = kubbsForFieldKubbs
        }
        
        // Reset half inning counters
        batonCount = 0
        missCount = 0
        halfInningRuns = 0
        halfInningKings = 0
        runsAfterKingHit = 0
        throwHistory = []
        
        modifiedAt = Date()
    }
    
    mutating func endHalfInning() {
        // Handle uncleared field kubbs
        if fieldKubbs > 0 {
            if isTop {
                awayBaselineKubbs += fieldKubbs
            } else {
                homeBaselineKubbs += fieldKubbs
            }
        }
        
        modifiedAt = Date()
    }
    
    mutating func checkGameEnd() {
        // Check if home team is winning in bottom 9th (covers both walk-off and home team already winning after top 9th)
        if currentInning == 9 && !isTop && homeScore > awayScore {
            endGame(winner: "home")
            return
        }
        
        // Check for end of 9 innings
        if currentInning > 9 {
            if awayScore > homeScore {
                endGame(winner: "away")
            } else if homeScore > awayScore {
                endGame(winner: "home")
            } else {
                // Tie game - check king count
                if awayKings > homeKings {
                    endGame(winner: "away")
                } else if homeKings > awayKings {
                    endGame(winner: "home")
                }
                // Still tied - continue playing (extra innings)
            }
        }
    }
    
    mutating func endGame(winner: String) {
        gameOver = true
        self.winner = winner
        isComplete = true
        modifiedAt = Date()
    }
    
    // MARK: - Undo Functionality
    
    mutating func saveThrowState() {
        let state = BaseballKubbThrowState(
            fieldKubbs: fieldKubbs,
            awayBaselineKubbs: awayBaselineKubbs,
            homeBaselineKubbs: homeBaselineKubbs,
            awayScore: awayScore,
            homeScore: homeScore,
            awayKings: awayKings,
            homeKings: homeKings,
            batonCount: batonCount,
            missCount: missCount,
            halfInningRuns: halfInningRuns,
            halfInningKings: halfInningKings,
            runsAfterKingHit: runsAfterKingHit,
            kingThrowAttempts: kingThrowAttempts,
            firstThrowKubbsHit: firstThrowKubbsHit
        )
        throwHistory.append(state)
    }
    
    mutating func restoreThrowState() {
        if let lastState = throwHistory.popLast() {
            fieldKubbs = lastState.fieldKubbs
            awayBaselineKubbs = lastState.awayBaselineKubbs
            homeBaselineKubbs = lastState.homeBaselineKubbs
            awayScore = lastState.awayScore
            homeScore = lastState.homeScore
            awayKings = lastState.awayKings
            homeKings = lastState.homeKings
            batonCount = lastState.batonCount
            missCount = lastState.missCount
            halfInningRuns = lastState.halfInningRuns
            halfInningKings = lastState.halfInningKings
            runsAfterKingHit = lastState.runsAfterKingHit
            kingThrowAttempts = lastState.kingThrowAttempts
            firstThrowKubbsHit = lastState.firstThrowKubbsHit
            modifiedAt = Date()
        }
    }
    
    mutating func saveHalfInningState() {
        let state = BaseballKubbHalfInningState(
            currentInning: currentInning,
            isTop: isTop,
            fieldKubbs: fieldKubbs,
            awayBaselineKubbs: awayBaselineKubbs,
            homeBaselineKubbs: homeBaselineKubbs,
            awayScore: awayScore,
            homeScore: homeScore,
            awayKings: awayKings,
            homeKings: homeKings
        )
        halfInningHistory.append(state)
    }
    
    mutating func resetHalfInning() {
        batonCount = 0
        missCount = 0
        halfInningRuns = 0
        halfInningKings = 0
        runsAfterKingHit = 0
        throwHistory = []
        
        // Restore scores and baseline kubbs to start of half
        if let halfStart = halfInningHistory.last {
            awayScore = halfStart.awayScore
            homeScore = halfStart.homeScore
            awayKings = halfStart.awayKings
            homeKings = halfStart.homeKings
            awayBaselineKubbs = halfStart.awayBaselineKubbs
            homeBaselineKubbs = halfStart.homeBaselineKubbs
            fieldKubbs = halfStart.fieldKubbs
        }
        
        modifiedAt = Date()
    }
    
    // MARK: - CloudKit Integration
    
    static let recordType = "Baseball_Kubb_Session"
    
    init?(from record: CKRecord) {
        guard let id = record["sessionId"] as? String,
              let date = record["date"] as? Date,
              let awayTeam = record["awayTeam"] as? String,
              let homeTeam = record["homeTeam"] as? String,
              let currentInning = record["currentInning"] as? Int64,
              let isTop = record["isTop"] as? Int64,
              let awayScore = record["awayScore"] as? Int64,
              let homeScore = record["homeScore"] as? Int64,
              let awayKings = record["awayKings"] as? Int64,
              let homeKings = record["homeKings"] as? Int64,
              let fieldKubbs = record["fieldKubbs"] as? Int64,
              let fieldKubbsAtStartOfHalf = record["fieldKubbsAtStartOfHalf"] as? Int64,
              let awayBaselineKubbs = record["awayBaselineKubbs"] as? Int64,
              let homeBaselineKubbs = record["homeBaselineKubbs"] as? Int64,
              let batonCount = record["batonCount"] as? Int64,
              let missCount = record["missCount"] as? Int64,
              let halfInningRuns = record["halfInningRuns"] as? Int64,
              let halfInningKings = record["halfInningKings"] as? Int64,
              let runsAfterKingHit = record["runsAfterKingHit"] as? Int64,
              let kingThrowAttempts = record["kingThrowAttempts"] as? Int64,
              let firstThrowKubbsHit = record["firstThrowKubbsHit"] as? Int64,
              let gameOver = record["gameOver"] as? Int64,
              let isComplete = record["isComplete"] as? Int64,
              let createdAt = record["createdAt"] as? Date,
              let modifiedAt = record["modifiedAt"] as? Date else {
            return nil
        }
        
        // Parse userTeam with fallback to .away for existing records
        let userTeam: UserTeam
        if let userTeamString = record["userTeam"] as? String,
           let parsedUserTeam = UserTeam(rawValue: userTeamString) {
            userTeam = parsedUserTeam
        } else {
            userTeam = .away // Default for existing records without userTeam field
        }
        
        self.id = id
        self.date = date
        self.awayTeam = awayTeam
        self.homeTeam = homeTeam
        self.userTeam = userTeam
        self.currentInning = Int(currentInning)
        self.isTop = isTop == 1
        self.awayScore = Int(awayScore)
        self.homeScore = Int(homeScore)
        self.awayKings = Int(awayKings)
        self.homeKings = Int(homeKings)
        self.fieldKubbs = Int(fieldKubbs)
        self.fieldKubbsAtStartOfHalf = Int(fieldKubbsAtStartOfHalf)
        self.awayBaselineKubbs = Int(awayBaselineKubbs)
        self.homeBaselineKubbs = Int(homeBaselineKubbs)
        self.batonCount = Int(batonCount)
        self.missCount = Int(missCount)
        self.halfInningRuns = Int(halfInningRuns)
        self.halfInningKings = Int(halfInningKings)
        self.runsAfterKingHit = Int(runsAfterKingHit)
        self.kingThrowAttempts = Int(kingThrowAttempts)
        self.firstThrowKubbsHit = Int(firstThrowKubbsHit)
        self.gameOver = gameOver == 1
        self.isComplete = isComplete == 1
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        
        // Parse optional fields
        self.winner = record["winner"] as? String
        
        // Parse history from JSON strings
        if let throwHistoryData = record["throwHistory"] as? String,
           let throwHistoryJSON = throwHistoryData.data(using: .utf8) {
            self.throwHistory = (try? JSONDecoder().decode([BaseballKubbThrowState].self, from: throwHistoryJSON)) ?? []
        } else {
            self.throwHistory = []
        }
        
        if let halfInningHistoryData = record["halfInningHistory"] as? String,
           let halfInningHistoryJSON = halfInningHistoryData.data(using: .utf8) {
            self.halfInningHistory = (try? JSONDecoder().decode([BaseballKubbHalfInningState].self, from: halfInningHistoryJSON)) ?? []
        } else {
            self.halfInningHistory = []
        }
        
        if let scoreboardHistoryData = record["scoreboardHistory"] as? String,
           let scoreboardHistoryJSON = scoreboardHistoryData.data(using: .utf8) {
            self.scoreboardHistory = (try? JSONDecoder().decode([BaseballKubbScoreboardEntry].self, from: scoreboardHistoryJSON)) ?? []
        } else {
            self.scoreboardHistory = []
        }
    }
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType)
        
        record["sessionId"] = id
        record["date"] = date
        record["awayTeam"] = awayTeam
        record["homeTeam"] = homeTeam
        record["userTeam"] = userTeam.rawValue
        record["currentInning"] = Int64(currentInning)
        record["isTop"] = isTop ? 1 : 0
        record["awayScore"] = Int64(awayScore)
        record["homeScore"] = Int64(homeScore)
        record["awayKings"] = Int64(awayKings)
        record["homeKings"] = Int64(homeKings)
        record["fieldKubbs"] = Int64(fieldKubbs)
        record["fieldKubbsAtStartOfHalf"] = Int64(fieldKubbsAtStartOfHalf)
        record["awayBaselineKubbs"] = Int64(awayBaselineKubbs)
        record["homeBaselineKubbs"] = Int64(homeBaselineKubbs)
        record["batonCount"] = Int64(batonCount)
        record["missCount"] = Int64(missCount)
        record["halfInningRuns"] = Int64(halfInningRuns)
        record["halfInningKings"] = Int64(halfInningKings)
        record["runsAfterKingHit"] = Int64(runsAfterKingHit)
        record["kingThrowAttempts"] = Int64(kingThrowAttempts)
        record["firstThrowKubbsHit"] = Int64(firstThrowKubbsHit)
        record["gameOver"] = gameOver ? 1 : 0
        record["isComplete"] = isComplete ? 1 : 0
        record["createdAt"] = createdAt
        record["modifiedAt"] = modifiedAt
        
        // Store optional fields
        if let winner = winner {
            record["winner"] = winner
        }
        
        // Store history as JSON strings
        if let throwHistoryData = try? JSONEncoder().encode(throwHistory),
           let throwHistoryString = String(data: throwHistoryData, encoding: .utf8) {
            record["throwHistory"] = throwHistoryString
        }
        
        if let halfInningHistoryData = try? JSONEncoder().encode(halfInningHistory),
           let halfInningHistoryString = String(data: halfInningHistoryData, encoding: .utf8) {
            record["halfInningHistory"] = halfInningHistoryString
        }
        
        if let scoreboardHistoryData = try? JSONEncoder().encode(scoreboardHistory),
           let scoreboardHistoryString = String(data: scoreboardHistoryData, encoding: .utf8) {
            record["scoreboardHistory"] = scoreboardHistoryString
        }
        
        return record
    }
}

struct BaseballKubbThrowState: Codable {
    let fieldKubbs: Int
    let awayBaselineKubbs: Int
    let homeBaselineKubbs: Int
    let awayScore: Int
    let homeScore: Int
    let awayKings: Int
    let homeKings: Int
    let batonCount: Int
    let missCount: Int
    let halfInningRuns: Int
    let halfInningKings: Int
    let runsAfterKingHit: Int
    let kingThrowAttempts: Int
    let firstThrowKubbsHit: Int
}

struct BaseballKubbHalfInningState: Codable {
    let currentInning: Int
    let isTop: Bool
    let fieldKubbs: Int
    let awayBaselineKubbs: Int
    let homeBaselineKubbs: Int
    let awayScore: Int
    let homeScore: Int
    let awayKings: Int
    let homeKings: Int
}

struct BaseballKubbScoreboardEntry: Codable {
    let inning: Int
    let isTop: Bool
    let awayRuns: Int
    let awayKings: Int
    let homeRuns: Int
    let homeKings: Int
}
