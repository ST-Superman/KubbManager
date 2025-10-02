//
//  InkastBlastSession.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 1/15/25.
//

import Foundation
import CloudKit

enum GamePhase: String, CaseIterable, Codable {
    case early = "Early Game"
    case mid = "Mid Game"
    case end = "End Game"
    case all = "All Phases"
    
    var kubbRange: ClosedRange<Int> {
        switch self {
        case .early:
            return 1...3
        case .mid:
            return 4...7
        case .end:
            return 8...10
        case .all:
            return 1...10
        }
    }
    
    var description: String {
        switch self {
        case .early:
            return "Practice with 1-3 kubbs"
        case .mid:
            return "Practice with 4-7 kubbs"
        case .end:
            return "Practice with 8-10 kubbs"
        case .all:
            return "Practice with 1-10 kubbs (random)"
        }
    }
}

struct InkastBlastSessionData: Identifiable, Codable {
    let id: String
    let date: Date
    let gamePhase: GamePhase
    var startTime: Date
    var endTime: Date?
    var isComplete: Bool
    var isPaused: Bool
    var totalRounds: Int
    var totalInkastKubbs: Int
    var totalKubbsClearedFirstThrow: Int
    var totalBatonsUsed: Int
    var totalPenaltyKubbs: Int
    var totalNeighborKubbs: Int
    var totalMisses: Int
    var rounds: [InkastBlastRoundData]
    let createdAt: Date
    var modifiedAt: Date
    
    init(id: String = UUID().uuidString,
         date: Date = Date(),
         gamePhase: GamePhase,
         startTime: Date = Date()) {
        self.id = id
        self.date = date
        self.gamePhase = gamePhase
        self.startTime = startTime
        self.endTime = nil
        self.isComplete = false
        self.isPaused = false
        self.totalRounds = 0
        self.totalInkastKubbs = 0
        self.totalKubbsClearedFirstThrow = 0
        self.totalBatonsUsed = 0
        self.totalPenaltyKubbs = 0
        self.totalNeighborKubbs = 0
        self.totalMisses = 0
        self.rounds = []
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
    
    // MARK: - Computed Properties
    
    var currentRound: InkastBlastRoundData? {
        rounds.first { !$0.isComplete }
    }
    
    var completedRounds: [InkastBlastRoundData] {
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
    
    var totalNeighbors: Int {
        return totalNeighborKubbs
    }
    
    var totalPenaltyKubbsCount: Int {
        return self.totalPenaltyKubbs
    }
    
    var kubbsOutOfBounds: Int {
        return rounds.reduce(0) { $0 + $1.kubbsOutFirstAttempt + $1.kubbsOutSecondAttempt }
    }
    
    // MARK: - Session Management
    
    mutating func addRound(_ round: InkastBlastRoundData) {
        rounds.append(round)
        totalRounds += 1
        totalInkastKubbs += round.inkastKubbs
        totalKubbsClearedFirstThrow += round.kubbsClearedFirstThrow
        totalBatonsUsed += round.batonsUsed
        totalPenaltyKubbs += round.penaltyKubbs
        totalNeighborKubbs += round.neighborKubbs
        totalMisses += round.misses
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
    
    // MARK: - CloudKit Integration
    
    static let recordType = "InkastBlast_Session"
    
    init?(from record: CKRecord) {
        guard let id = record["sessionId"] as? String,
              let date = record["date"] as? Date,
              let gamePhaseString = record["gamePhase"] as? String,
              let gamePhase = GamePhase(rawValue: gamePhaseString),
              let startTime = record["startTime"] as? Date,
              let isComplete = record["isComplete"] as? Int64,
              let isPaused = record["isPaused"] as? Int64,
              let totalRounds = record["totalRounds"] as? Int64,
              let totalInkastKubbs = record["totalInkastKubbs"] as? Int64,
              let totalKubbsClearedFirstThrow = record["totalKubbsClearedFirstThrow"] as? Int64,
              let totalBatonsUsed = record["totalBatonsUsed"] as? Int64,
              let totalPenaltyKubbs = record["totalPenaltyKubbs"] as? Int64,
              let totalNeighborKubbs = record["totalNeighborKubbs"] as? Int64,
              let totalMisses = record["totalMisses"] as? Int64,
              let createdAt = record["createdAt"] as? Date,
              let modifiedAt = record["modifiedAt"] as? Date else {
            return nil
        }
        
        self.id = id
        self.date = date
        self.gamePhase = gamePhase
        self.startTime = startTime
        self.endTime = record["endTime"] as? Date
        self.isComplete = isComplete == 1
        self.isPaused = isPaused == 1
        self.totalRounds = Int(totalRounds)
        self.totalInkastKubbs = Int(totalInkastKubbs)
        self.totalKubbsClearedFirstThrow = Int(totalKubbsClearedFirstThrow)
        self.totalBatonsUsed = Int(totalBatonsUsed)
        self.totalPenaltyKubbs = Int(totalPenaltyKubbs)
        self.totalNeighborKubbs = Int(totalNeighborKubbs)
        self.totalMisses = Int(totalMisses)
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        
        // Parse rounds from JSON string
        if let roundsData = record["rounds"] as? String,
           let roundsJSON = roundsData.data(using: .utf8) {
            self.rounds = (try? JSONDecoder().decode([InkastBlastRoundData].self, from: roundsJSON)) ?? []
        } else {
            self.rounds = []
        }
    }
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType)
        
        record["sessionId"] = id
        record["date"] = date
        record["gamePhase"] = gamePhase.rawValue
        record["startTime"] = startTime
        record["endTime"] = endTime
        record["isComplete"] = isComplete ? 1 : 0
        record["isPaused"] = isPaused ? 1 : 0
        record["totalRounds"] = Int64(totalRounds)
        record["totalInkastKubbs"] = Int64(totalInkastKubbs)
        record["totalKubbsClearedFirstThrow"] = Int64(totalKubbsClearedFirstThrow)
        record["totalBatonsUsed"] = Int64(totalBatonsUsed)
        record["totalPenaltyKubbs"] = Int64(totalPenaltyKubbs)
        record["totalNeighborKubbs"] = Int64(totalNeighborKubbs)
        record["totalMisses"] = Int64(totalMisses)
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

extension InkastBlastSessionData {
    func toPracticeSession() -> PracticeSession {
        // Use private initializer to avoid logging for statistics conversion
        return PracticeSession(
            id: id,
            date: date,
            target: totalInkastKubbs, // Use total inkast kubbs as target
            totalKubbs: totalKubbsKnockedDown,
            totalBatons: totalBatonsUsed,
            startTime: startTime,
            endTime: endTime,
            isComplete: isComplete,
            isPaused: false,
            rounds: [],
            createdAt: createdAt,
            modifiedAt: modifiedAt
        )
    }
}
