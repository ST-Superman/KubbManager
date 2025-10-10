//
//  FullGameSimRound.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 1/15/25.
//

import Foundation

struct FullGameSimRoundStruct: Identifiable, Codable {
    let id: String
    let roundNumber: Int
    var eightMeterData: EightMeterRoundDataStruct
    var inkastData: InkastRoundDataStruct
    var blastData: BlastRoundDataStruct
    var baselineKubbsHit: Int // Track baseline kubbs hit this round (separate from 8-meter)
    var isComplete: Bool
    let createdAt: Date
    
    // A-Line (Advantage Line) tracking
    var hasALine: Bool = false // Whether this round has A-Line advantage
    var unclearedFieldKubbs: Int = 0 // Field kubbs left uncleared after this round completes
    var gamePhaseWhenALineAwarded: GamePhase? = nil // Phase when opponent earned A-Line
    
    init(id: String = UUID().uuidString, roundNumber: Int) {
        self.id = id
        self.roundNumber = roundNumber
        self.eightMeterData = EightMeterRoundDataStruct()
        self.inkastData = InkastRoundDataStruct()
        self.blastData = BlastRoundDataStruct()
        self.baselineKubbsHit = 0
        self.isComplete = false
        self.createdAt = Date()
        self.hasALine = false
        self.unclearedFieldKubbs = 0
        self.gamePhaseWhenALineAwarded = nil
    }
    
    // MARK: - Computed Properties
    
    var totalBatonsUsed: Int {
        return eightMeterData.batonsUsed + inkastData.batonsUsed + blastData.batonsUsed
    }
    
    var totalMisses: Int {
        return eightMeterData.misses + inkastData.misses + blastData.misses
    }
    
    var totalKubbsKnockedDown: Int {
        return eightMeterData.hits + blastData.totalKubbsKnockedDown + baselineKubbsHit
    }
    
    var totalHits: Int {
        return eightMeterData.hits + inkastData.hits + blastData.hits
    }
    
    var accuracy: Double {
        let totalThrows = totalBatonsUsed
        guard totalThrows > 0 else { return 0.0 }
        return Double(totalHits) / Double(totalThrows)
    }
    
    var eightMeterAccuracy: Double {
        guard eightMeterData.batonsUsed > 0 else { return 0.0 }
        return Double(eightMeterData.hits) / Double(eightMeterData.batonsUsed)
    }
    
    var inkastAccuracy: Double {
        guard inkastData.batonsUsed > 0 else { return 0.0 }
        return Double(inkastData.hits) / Double(inkastData.batonsUsed)
    }
    
    var blastAccuracy: Double {
        guard blastData.batonsUsed > 0 else { return 0.0 }
        return Double(blastData.hits) / Double(blastData.batonsUsed)
    }
    
    /// Calculate handicap for this round (only for rounds 2+, since round 1 has no inkast/blast)
    var handicap: Int? {
        guard roundNumber > 1, let inkastBlastRound = toInkastBlastRound() else { return nil }
        let target = inkastBlastRound.targetBatons
        let actual = inkastBlastRound.batonsUsed
        return actual - target
    }
    
    /// Total field kubb clearing misses (inkast + blast misses for rounds 2+)
    var fieldClearingMisses: Int {
        guard roundNumber > 1 else { return 0 }
        return inkastData.misses + blastData.misses
    }
    
    // MARK: - Round Management
    
    mutating func completeRound() {
        isComplete = true
    }
    
    mutating func resetRound() {
        eightMeterData = EightMeterRoundDataStruct()
        inkastData = InkastRoundDataStruct()
        blastData = BlastRoundDataStruct()
        isComplete = false
    }
    
    // MARK: - Conversion Methods for Statistics
    
    /// Determines which game phase this round belongs to for statistics purposes
    /// Based on the number of inkast kubbs in play
    func gamePhase() -> GamePhase {
        let kubbCount = inkastData.inkastKubbs
        
        switch kubbCount {
        case 0..<4:
            return .early
        case 4...6:
            return .mid
        default: // 7+
            return .end
        }
    }
    
    /// Converts this Full Game Sim round to an Inkast & Blast round for statistics aggregation
    /// Only includes inkast and blast data (not baseline/8-meter throws)
    func toInkastBlastRound() -> InkastBlastRoundData? {
        // Round 1 has no inkast phase, so skip it
        guard roundNumber > 1 else { return nil }
        
        // Create an Inkast & Blast round with the inkast data
        var round = InkastBlastRoundData(
            id: id,
            roundNumber: roundNumber,
            inkastKubbs: inkastData.inkastKubbs
        )
        
        // Copy inkast results
        round.kubbsOutFirstAttempt = inkastData.kubbsOutFirstAttempt
        round.kubbsOutSecondAttempt = inkastData.kubbsOutSecondAttempt
        round.penaltyKubbs = inkastData.penaltyKubbs
        round.neighborKubbs = inkastData.neighborKubbs
        
        // Copy blast data (field kubb clearing)
        round.kubbsClearedFirstThrow = blastData.kubbsClearedFirstThrow
        round.batonsUsed = blastData.batonsUsed
        round.misses = blastData.misses
        round.isComplete = isComplete
        
        // Convert blast baton throws to InkastBatonThrowData
        round.batonThrows = blastData.batonThrows.map { batonThrow in
            InkastBatonThrowData(
                id: batonThrow.id,
                isHit: batonThrow.isHit,
                kubbsHit: batonThrow.kubbsHit,
                throwNumber: batonThrow.throwNumber
            )
        }
        
        return round
    }
    
    /// Returns 8-meter statistics from this round (baseline throws and Round 1's 8-meter only phase)
    /// This data should be aggregated with standalone 8-meter training sessions
    func eightMeterStatistics() -> (batonsUsed: Int, hits: Int, misses: Int, accuracy: Double) {
        let batonsUsed = eightMeterData.batonsUsed
        let hits = eightMeterData.hits
        let misses = eightMeterData.misses
        let accuracy = eightMeterData.accuracy
        
        return (batonsUsed, hits, misses, accuracy)
    }
}

struct EightMeterRoundDataStruct: Codable {
    var hits: Int = 0
    var misses: Int = 0
    var batonsUsed: Int = 0
    var batonThrows: [EightMeterBatonThrowStruct] = []
    
    // A-Line statistics
    var hitsFromALine: Int = 0
    var missesFromALine: Int = 0
    var batonsUsedFromALine: Int = 0
    
    var isComplete: Bool {
        return batonsUsed >= 2 // 8-meter training uses 2 batons
    }
    
    var accuracy: Double {
        guard batonsUsed > 0 else { return 0.0 }
        return Double(hits) / Double(batonsUsed)
    }
    
    var accuracyFromALine: Double {
        guard batonsUsedFromALine > 0 else { return 0.0 }
        return Double(hitsFromALine) / Double(batonsUsedFromALine)
    }
    
    mutating func addBatonThrow(isHit: Bool, fromALine: Bool = false) {
        let batonThrow = EightMeterBatonThrowStruct(
            isHit: isHit,
            throwNumber: batonThrows.count + 1,
            fromALine: fromALine
        )
        batonThrows.append(batonThrow)
        
        batonsUsed += 1
        
        if isHit {
            hits += 1
        } else {
            misses += 1
        }
        
        // Track A-Line statistics separately
        if fromALine {
            batonsUsedFromALine += 1
            if isHit {
                hitsFromALine += 1
            } else {
                missesFromALine += 1
            }
        }
    }
}

struct InkastRoundDataStruct: Codable {
    var inkastKubbs: Int = 0
    var kubbsOutFirstAttempt: Int = 0
    var kubbsOutSecondAttempt: Int = 0
    var penaltyKubbs: Int = 0
    var neighborKubbs: Int = 0
    var hits: Int = 0
    var misses: Int = 0
    var batonsUsed: Int = 0
    var batonThrows: [InkastBatonThrowStruct] = []
    
    var isInkastComplete: Bool {
        return kubbsOutFirstAttempt == 0 || kubbsOutSecondAttempt > 0
    }
    
    var totalKubbsInBounds: Int {
        return inkastKubbs - penaltyKubbs
    }
    
    var totalFieldKubbsForAttacking: Int {
        return inkastKubbs // Include penalty kubbs in attacking phase
    }
    
    var accuracy: Double {
        guard batonsUsed > 0 else { return 0.0 }
        return Double(hits) / Double(batonsUsed)
    }
    
    mutating func recordInkastResults(firstAttemptOut: Int, secondAttemptOut: Int, neighbors: Int) {
        kubbsOutFirstAttempt = firstAttemptOut
        kubbsOutSecondAttempt = secondAttemptOut
        penaltyKubbs = secondAttemptOut
        neighborKubbs = neighbors
    }
    
    mutating func addBatonThrow(isHit: Bool, kubbsHit: Int = 0) {
        let batonThrow = InkastBatonThrowStruct(
            isHit: isHit,
            kubbsHit: kubbsHit,
            throwNumber: batonThrows.count + 1
        )
        batonThrows.append(batonThrow)
        
        batonsUsed += 1
        
        if isHit {
            hits += 1
        } else {
            misses += 1
        }
    }
}

struct BlastRoundDataStruct: Codable {
    var kubbsClearedFirstThrow: Int = 0
    var hits: Int = 0
    var misses: Int = 0
    var batonsUsed: Int = 0
    var batonThrows: [BlastBatonThrowStruct] = []
    
    // A-Line statistics
    var hitsFromALine: Int = 0
    var missesFromALine: Int = 0
    var batonsUsedFromALine: Int = 0
    
    var isComplete: Bool {
        return kubbsClearedFirstThrow >= 5 // All field kubbs cleared
    }
    
    var totalKubbsKnockedDown: Int {
        return batonThrows.reduce(0) { total, batonThrow in
            return total + (batonThrow.isHit ? batonThrow.kubbsHit : 0)
        }
    }
    
    var accuracy: Double {
        guard batonsUsed > 0 else { return 0.0 }
        return Double(hits) / Double(batonsUsed)
    }
    
    var accuracyFromALine: Double {
        guard batonsUsedFromALine > 0 else { return 0.0 }
        return Double(hitsFromALine) / Double(batonsUsedFromALine)
    }
    
    mutating func addBatonThrow(isHit: Bool, kubbsHit: Int = 0, fromALine: Bool = false) {
        let batonThrow = BlastBatonThrowStruct(
            isHit: isHit,
            kubbsHit: kubbsHit,
            throwNumber: batonThrows.count + 1,
            fromALine: fromALine
        )
        batonThrows.append(batonThrow)
        
        batonsUsed += 1
        
        if isHit {
            hits += 1
            kubbsClearedFirstThrow += kubbsHit
        } else {
            misses += 1
        }
        
        // Track A-Line statistics separately
        if fromALine {
            batonsUsedFromALine += 1
            if isHit {
                hitsFromALine += 1
            } else {
                missesFromALine += 1
            }
        }
    }
}

// MARK: - Baton Throw Data Structures

struct EightMeterBatonThrowStruct: Identifiable, Codable {
    let id: String
    let isHit: Bool
    let throwNumber: Int
    let timestamp: Date
    let fromALine: Bool
    
    init(id: String = UUID().uuidString, isHit: Bool, throwNumber: Int, fromALine: Bool = false) {
        self.id = id
        self.isHit = isHit
        self.throwNumber = throwNumber
        self.timestamp = Date()
        self.fromALine = fromALine
    }
}

struct InkastBatonThrowStruct: Identifiable, Codable {
    let id: String
    let isHit: Bool
    let kubbsHit: Int
    let throwNumber: Int
    let timestamp: Date
    
    init(id: String = UUID().uuidString, isHit: Bool, kubbsHit: Int, throwNumber: Int) {
        self.id = id
        self.isHit = isHit
        self.kubbsHit = kubbsHit
        self.throwNumber = throwNumber
        self.timestamp = Date()
    }
}

struct BlastBatonThrowStruct: Identifiable, Codable {
    let id: String
    let isHit: Bool
    let kubbsHit: Int
    let throwNumber: Int
    let timestamp: Date
    let fromALine: Bool
    
    init(id: String = UUID().uuidString, isHit: Bool, kubbsHit: Int, throwNumber: Int, fromALine: Bool = false) {
        self.id = id
        self.isHit = isHit
        self.kubbsHit = kubbsHit
        self.throwNumber = throwNumber
        self.timestamp = Date()
        self.fromALine = fromALine
    }
}
