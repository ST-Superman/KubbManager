//
//  FullGameSimSession.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 1/15/25.
//

import Foundation
import CloudKit

enum FullGamePhase: String, CaseIterable, Codable {
    case attacking = "Attacking"
    case inkast = "Inkast"
    case roundComplete = "Round Complete"
}

struct FullGameSimSessionStruct: Identifiable, Codable {
    let id: String
    let date: Date
    var startTime: Date
    var endTime: Date?
    var isComplete: Bool
    var isPaused: Bool
    var currentRound: Int
    var currentPhase: FullGamePhase
    var totalRounds: Int
    var totalInkastKubbs: Int
    var totalKubbsClearedFirstThrow: Int
    var totalBatonsUsed: Int
    var totalPenaltyKubbs: Int
    var totalNeighborKubbs: Int
    var totalMisses: Int
    var totalEightMeterHits: Int
    var totalEightMeterBatons: Int
    var team1BaselineKubbs: Int // Team 1's remaining baseline kubbs
    var team2BaselineKubbs: Int // Team 2's remaining baseline kubbs
    var team1UnclearedKubbs: Int = 0 // Field kubbs Team 1 left uncleared (carry to their next attacking round)
    var team2UnclearedKubbs: Int = 0 // Field kubbs Team 2 left uncleared (carry to their next attacking round)
    var kingHit: Bool // Game ends when king is hit
    var rounds: [FullGameSimRoundStruct]
    let createdAt: Date
    var modifiedAt: Date
    
    init(id: String = UUID().uuidString, date: Date = Date(), startTime: Date = Date()) {
        self.id = id
        self.date = date
        self.startTime = startTime
        self.endTime = nil
        self.isComplete = false
        self.isPaused = false
        self.currentRound = 1
        self.currentPhase = .attacking
        self.totalRounds = 0
        self.totalInkastKubbs = 0
        self.totalKubbsClearedFirstThrow = 0
        self.totalBatonsUsed = 0
        self.totalPenaltyKubbs = 0
        self.totalNeighborKubbs = 0
        self.totalMisses = 0
        self.totalEightMeterHits = 0
        self.totalEightMeterBatons = 0
        self.team1BaselineKubbs = 5 // Start with 5 baseline kubbs for each team
        self.team2BaselineKubbs = 5
        self.team1UnclearedKubbs = 0 // No uncleared kubbs at start
        self.team2UnclearedKubbs = 0
        self.kingHit = false // Game hasn't ended yet
        self.rounds = []
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
    
    // MARK: - Computed Properties
    
    var currentRoundData: FullGameSimRoundStruct? {
        rounds.first { $0.roundNumber == currentRound }
    }
    
    var currentAttackingTeam: Int {
        return currentRound % 2 == 1 ? 1 : 2 // Team 1 attacks on odd rounds, Team 2 on even rounds
    }
    
    var currentBaselineKubbs: Int {
        return currentAttackingTeam == 1 ? team1BaselineKubbs : team2BaselineKubbs
    }
    
    var completedRounds: [FullGameSimRoundStruct] {
        rounds.filter { $0.isComplete }
    }
    
    var totalKubbsKnockedDown: Int {
        return rounds.reduce(0) { total, round in
            return total + round.totalKubbsKnockedDown
        }
    }
    
    var averageKubbsPerBaton: Double {
        guard totalBatonsUsed > 0 else { return 0.0 }
        return Double(totalKubbsKnockedDown) / Double(totalBatonsUsed)
    }
    
    var averageKubbsPerRound: Double {
        guard totalRounds > 0 else { return 0.0 }
        return Double(totalInkastKubbs) / Double(totalRounds)
    }
    
    var averageBatonsPerRound: Double {
        guard totalRounds > 0 else { return 0.0 }
        return Double(totalBatonsUsed) / Double(totalRounds)
    }
    
    var penaltyRate: Double {
        guard totalInkastKubbs > 0 else { return 0.0 }
        return Double(totalPenaltyKubbs) / Double(totalInkastKubbs)
    }
    
    var neighborRate: Double {
        guard totalInkastKubbs > 0 else { return 0.0 }
        return Double(totalNeighborKubbs) / Double(totalInkastKubbs)
    }
    
    var eightMeterAccuracy: Double {
        guard totalEightMeterBatons > 0 else { return 0.0 }
        return Double(totalEightMeterHits) / Double(totalEightMeterBatons)
    }
    
    var kubbsOutOfBounds: Int {
        return rounds.reduce(0) { $0 + $1.inkastData.kubbsOutFirstAttempt + $1.inkastData.kubbsOutSecondAttempt }
    }
    
    var totalBlastKubbs: Int {
        return rounds.reduce(0) { total, round in
            return total + round.blastData.hits
        }
    }
    
    /// Overall handicap performance (rounds 2+ only, since round 1 has no field kubbs)
    var overallHandicap: Double {
        let roundsWithFieldKubbs = rounds.filter { $0.roundNumber > 1 }
        guard !roundsWithFieldKubbs.isEmpty else { return 0.0 }
        
        let totalHandicap = roundsWithFieldKubbs.compactMap { $0.handicap }.reduce(0, +)
        return Double(totalHandicap) / Double(roundsWithFieldKubbs.count)
    }
    
    var outcome: String {
        if !isComplete {
            return "In Progress"
        }
        // Victory if king is hit (game completed successfully)
        return kingHit ? "Victory" : "Defeat"
    }
    
    // MARK: - Round Management
    
    var batonLimit: Int {
        switch currentRound {
        case 1:
            return 2
        case 2:
            return 4
        default:
            return 6
        }
    }
    
    var canProceedToNextPhase: Bool {
        guard let round = currentRoundData else { return false }
        
        switch currentPhase {
        case .attacking:
            return round.eightMeterData.isComplete
        case .inkast:
            return round.inkastData.isInkastComplete
        case .roundComplete:
            return true
        }
    }
    
    // MARK: - Session Management
    
    mutating func addRound(_ round: FullGameSimRoundStruct) {
        rounds.append(round)
        totalRounds += 1
        totalInkastKubbs += round.inkastData.inkastKubbs
        totalKubbsClearedFirstThrow += round.blastData.kubbsClearedFirstThrow
        totalBatonsUsed += round.totalBatonsUsed
        totalPenaltyKubbs += round.inkastData.penaltyKubbs
        totalNeighborKubbs += round.inkastData.neighborKubbs
        totalMisses += round.totalMisses
        totalEightMeterHits += round.eightMeterData.hits
        totalEightMeterBatons += round.eightMeterData.batonsUsed
        modifiedAt = Date()
    }
    
    mutating func completeSession() {
        isComplete = true
        endTime = Date()
        modifiedAt = Date()
    }
    
    mutating func pauseSession() {
        isPaused = true
        endTime = Date()
        modifiedAt = Date()
    }
    
    mutating func resumeSession() {
        isPaused = false
        endTime = nil
        modifiedAt = Date()
    }
    
    mutating func recordBaselineKubbsHit(_ count: Int) {
        if currentAttackingTeam == 1 {
            team1BaselineKubbs = max(0, team1BaselineKubbs - count)
        } else {
            team2BaselineKubbs = max(0, team2BaselineKubbs - count)
        }
        modifiedAt = Date()
    }
    
    mutating func nextPhase() {
        switch currentPhase {
        case .attacking:
            if currentRound == 1 {
                // Round 1 only has attacking phase
                currentPhase = .roundComplete
            } else {
                // Rounds 2+ have inkast phase
                currentPhase = .inkast
            }
        case .inkast:
            currentPhase = .attacking
        case .roundComplete:
            // Move to next round
            currentRound += 1
            currentPhase = .attacking
        }
        modifiedAt = Date()
    }
    
    // MARK: - CloudKit Integration
    
    static let recordType = "FullGameSim_Session"
    
    init?(from record: CKRecord) {
        guard let id = record["sessionId"] as? String,
              let date = record["date"] as? Date,
              let startTime = record["startTime"] as? Date,
              let isComplete = record["isComplete"] as? Int64,
              let isPaused = record["isPaused"] as? Int64,
              let currentRound = record["currentRound"] as? Int64,
              let currentPhaseString = record["currentPhase"] as? String,
              let currentPhase = FullGamePhase(rawValue: currentPhaseString),
              let totalRounds = record["totalRounds"] as? Int64,
              let totalInkastKubbs = record["totalInkastKubbs"] as? Int64,
              let totalKubbsClearedFirstThrow = record["totalKubbsClearedFirstThrow"] as? Int64,
              let totalBatonsUsed = record["totalBatonsUsed"] as? Int64,
              let totalPenaltyKubbs = record["totalPenaltyKubbs"] as? Int64,
              let totalNeighborKubbs = record["totalNeighborKubbs"] as? Int64,
              let totalMisses = record["totalMisses"] as? Int64,
              let totalEightMeterHits = record["totalEightMeterHits"] as? Int64,
              let totalEightMeterBatons = record["totalEightMeterBatons"] as? Int64,
              let createdAt = record["createdAt"] as? Date,
              let modifiedAt = record["modifiedAt"] as? Date else {
            return nil
        }
        
        self.id = id
        self.date = date
        self.startTime = startTime
        self.endTime = record["endTime"] as? Date
        self.isComplete = isComplete == 1
        self.isPaused = isPaused == 1
        self.currentRound = Int(currentRound)
        self.currentPhase = currentPhase
        self.totalRounds = Int(totalRounds)
        self.totalInkastKubbs = Int(totalInkastKubbs)
        self.totalKubbsClearedFirstThrow = Int(totalKubbsClearedFirstThrow)
        self.totalBatonsUsed = Int(totalBatonsUsed)
        self.totalPenaltyKubbs = Int(totalPenaltyKubbs)
        self.totalNeighborKubbs = Int(totalNeighborKubbs)
        self.totalMisses = Int(totalMisses)
        self.totalEightMeterHits = Int(totalEightMeterHits)
        self.totalEightMeterBatons = Int(totalEightMeterBatons)
        self.team1BaselineKubbs = Int(record["team1BaselineKubbs"] as? Int64 ?? 5)
        self.team2BaselineKubbs = Int(record["team2BaselineKubbs"] as? Int64 ?? 5)
        self.team1UnclearedKubbs = Int(record["team1UnclearedKubbs"] as? Int64 ?? 0)
        self.team2UnclearedKubbs = Int(record["team2UnclearedKubbs"] as? Int64 ?? 0)
        self.kingHit = (record["kingHit"] as? Int64 ?? 0) == 1
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        
        // Parse rounds from JSON string
        if let roundsData = record["rounds"] as? String,
           let roundsJSON = roundsData.data(using: .utf8) {
            self.rounds = (try? JSONDecoder().decode([FullGameSimRoundStruct].self, from: roundsJSON)) ?? []
        } else {
            self.rounds = []
        }
    }
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType)
        
        record["sessionId"] = id
        record["date"] = date
        record["startTime"] = startTime
        record["endTime"] = endTime
        record["isComplete"] = isComplete ? 1 : 0
        record["isPaused"] = isPaused ? 1 : 0
        record["currentRound"] = Int64(currentRound)
        record["currentPhase"] = currentPhase.rawValue
        record["totalRounds"] = Int64(totalRounds)
        record["totalInkastKubbs"] = Int64(totalInkastKubbs)
        record["totalKubbsClearedFirstThrow"] = Int64(totalKubbsClearedFirstThrow)
        record["totalBatonsUsed"] = Int64(totalBatonsUsed)
        record["totalPenaltyKubbs"] = Int64(totalPenaltyKubbs)
        record["totalNeighborKubbs"] = Int64(totalNeighborKubbs)
        record["totalMisses"] = Int64(totalMisses)
        record["totalEightMeterHits"] = Int64(totalEightMeterHits)
        record["totalEightMeterBatons"] = Int64(totalEightMeterBatons)
        record["team1BaselineKubbs"] = Int64(team1BaselineKubbs)
        record["team2BaselineKubbs"] = Int64(team2BaselineKubbs)
        record["team1UnclearedKubbs"] = Int64(team1UnclearedKubbs)
        record["team2UnclearedKubbs"] = Int64(team2UnclearedKubbs)
        record["kingHit"] = kingHit ? 1 : 0
        record["createdAt"] = createdAt
        record["modifiedAt"] = modifiedAt
        
        // Store rounds as JSON string
        if let roundsData = try? JSONEncoder().encode(rounds),
           let roundsString = String(data: roundsData, encoding: .utf8) {
            record["rounds"] = roundsString
        }
        
        return record
    }
}

// MARK: - Extensions

extension FullGameSimSessionStruct {
    func toPracticeSession() -> PracticeSession {
        // Use private initializer to avoid logging for statistics conversion
        return PracticeSession(
            id: id,
            date: date,
            target: totalInkastKubbs, // Use total inkast kubbs as target
            totalKubbs: totalKubbsKnockedDown,
            totalBatons: totalBatonsUsed,
            startTime: startTime,
            endTime: endTime ?? Date(),
            isComplete: isComplete,
            isPaused: false,
            rounds: [],
            createdAt: createdAt,
            modifiedAt: modifiedAt
        )
    }
    
    func toInkastBlastSession() -> InkastBlastSessionData {
        var session = InkastBlastSessionData(
            id: id,
            date: date,
            gamePhase: .all, // Full game sim covers all phases
            startTime: startTime
        )
        
        // Set additional properties
        session.endTime = endTime
        session.isComplete = isComplete
        session.isPaused = isPaused
        session.totalRounds = totalRounds
        session.totalInkastKubbs = totalInkastKubbs
        session.totalKubbsClearedFirstThrow = totalKubbsClearedFirstThrow
        session.totalBatonsUsed = totalBatonsUsed
        session.totalPenaltyKubbs = totalPenaltyKubbs
        session.totalNeighborKubbs = totalNeighborKubbs
        session.totalMisses = totalMisses
        session.rounds = [] // TODO: Convert rounds if needed
        session.modifiedAt = modifiedAt
        
        return session
    }
}
