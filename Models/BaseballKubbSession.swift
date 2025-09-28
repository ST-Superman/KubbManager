//
//  BaseballKubbSession.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 9/23/25.
//

import Foundation
import CloudKit

struct BaseballKubbSession: Identifiable, Codable {
    let id: String
    let date: Date
    var awayTeam: String
    var homeTeam: String
    var currentInning: Int
    var isTop: Bool // true = top (away), false = bottom (home)
    var awayScore: Int
    var homeScore: Int
    var awayKings: Int
    var homeKings: Int
    var fieldKubbs: Int
    var fieldKubbsAtStartOfHalf: Int
    var awayBaselineKubbs: Int
    var homeBaselineKubbs: Int
    var batonCount: Int
    var missCount: Int
    var halfInningRuns: Int
    var halfInningKings: Int
    var runsAfterKingHit: Int
    var gameOver: Bool
    var winner: String?
    var throwHistory: [BaseballKubbThrowState]
    var halfInningHistory: [BaseballKubbHalfInningState]
    var isComplete: Bool
    let createdAt: Date
    var modifiedAt: Date
    
    init(id: String = UUID().uuidString, date: Date = Date(), awayTeam: String = "", homeTeam: String = "") {
        self.id = id
        self.date = date
        self.awayTeam = awayTeam
        self.homeTeam = homeTeam
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
        self.gameOver = false
        self.winner = nil
        self.throwHistory = []
        self.halfInningHistory = []
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
    
    // MARK: - Scoreboard Data
    
    var scoreboardData: [(awayRuns: Int, awayKings: Int, homeRuns: Int, homeKings: Int)] {
        var data: [(awayRuns: Int, awayKings: Int, homeRuns: Int, homeKings: Int)] = []
        
        // Process each half-inning from history
        for (index, halfInning) in halfInningHistory.enumerated() {
            let nextHalfInning = index < halfInningHistory.count - 1 ? halfInningHistory[index + 1] : nil
            
            if halfInning.isTop {
                // Top half - away team scored
                let awayRuns = nextHalfInning?.awayScore ?? awayScore - halfInning.awayScore
                let awayKings = nextHalfInning?.awayKings ?? awayKings - halfInning.awayKings
                data.append((awayRuns: awayRuns, awayKings: awayKings, homeRuns: 0, homeKings: 0))
            } else {
                // Bottom half - home team scored
                let homeRuns = nextHalfInning?.homeScore ?? homeScore - halfInning.homeScore
                let homeKings = nextHalfInning?.homeKings ?? homeKings - halfInning.homeKings
                data.append((awayRuns: 0, awayKings: 0, homeRuns: homeRuns, homeKings: homeKings))
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
            runsAfterKingHit: runsAfterKingHit
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
              let gameOver = record["gameOver"] as? Int64,
              let isComplete = record["isComplete"] as? Int64,
              let createdAt = record["createdAt"] as? Date,
              let modifiedAt = record["modifiedAt"] as? Date else {
            return nil
        }
        
        self.id = id
        self.date = date
        self.awayTeam = awayTeam
        self.homeTeam = homeTeam
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
    }
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType)
        
        record["sessionId"] = id
        record["date"] = date
        record["awayTeam"] = awayTeam
        record["homeTeam"] = homeTeam
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
