//
//  InkastBlastRound.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 1/15/25.
//

import Foundation

struct InkastBlastRoundData: Identifiable, Codable {
    let id: String
    let roundNumber: Int
    var inkastKubbs: Int
    var kubbsOutFirstAttempt: Int
    var kubbsOutSecondAttempt: Int
    var penaltyKubbs: Int
    var neighborKubbs: Int
    var kubbsClearedFirstThrow: Int
    var batonsUsed: Int
    var misses: Int
    var isComplete: Bool
    var batonThrows: [InkastBatonThrowData]
    let createdAt: Date
    
    init(id: String = UUID().uuidString, 
         roundNumber: Int, 
         inkastKubbs: Int) {
        self.id = id
        self.roundNumber = roundNumber
        self.inkastKubbs = inkastKubbs
        self.kubbsOutFirstAttempt = 0
        self.kubbsOutSecondAttempt = 0
        self.penaltyKubbs = 0
        self.neighborKubbs = 0
        self.kubbsClearedFirstThrow = 0
        self.batonsUsed = 0
        self.misses = 0
        self.isComplete = false
        self.batonThrows = []
        self.createdAt = Date()
    }
    
    // MARK: - Computed Properties
    
    var totalKubbsInBounds: Int {
        return inkastKubbs - penaltyKubbs
    }
    
    var kubbsRemaining: Int {
        return totalKubbsInBounds - kubbsClearedFirstThrow
    }
    
    var totalKubbsKnockedDown: Int {
        return batonThrows.reduce(0) { total, batonThrow in
            return total + (batonThrow.isHit ? batonThrow.kubbsHit : 0)
        }
    }
    
    var averageKubbsPerBaton: Double {
        guard batonsUsed > 0 else { return 0.0 }
        return Double(totalKubbsKnockedDown) / Double(batonsUsed)
    }
    
    var targetBatons: Int {
        switch inkastKubbs {
        case 1:
            return 1
        case 2:
            return 1
        case 3...4:
            return 2
        case 5...7:
            return 3
        case 8...10:
            return 4
        default:
            return max(1, (inkastKubbs + 1) / 2) // Fallback calculation
        }
    }
    
    var performanceVsTarget: Int {
        return targetBatons - batonsUsed
    }
    
    var isUnderTarget: Bool {
        return batonsUsed < targetBatons
    }
    
    var isOverTarget: Bool {
        return batonsUsed > targetBatons
    }
    
    // MARK: - Round Management
    
    mutating func recordInkastResults(firstAttemptOut: Int, secondAttemptOut: Int, neighbors: Int) {
        kubbsOutFirstAttempt = firstAttemptOut
        kubbsOutSecondAttempt = secondAttemptOut
        penaltyKubbs = secondAttemptOut
        neighborKubbs = neighbors
    }
    
    mutating func addBatonThrow(isHit: Bool, kubbsHit: Int = 0) {
        let batonThrow = InkastBatonThrowData(
            isHit: isHit,
            kubbsHit: kubbsHit,
            throwNumber: batonThrows.count + 1
        )
        batonThrows.append(batonThrow)
        
        batonsUsed += 1
        
        if isHit {
            kubbsClearedFirstThrow += kubbsHit
        } else {
            misses += 1
        }
        
        // Check if round is complete (all field kubbs cleared)
        if kubbsClearedFirstThrow >= totalKubbsInBounds {
            isComplete = true
        }
    }
    
    mutating func completeRound() {
        isComplete = true
    }
    
    mutating func resetRound() {
        kubbsOutFirstAttempt = 0
        kubbsOutSecondAttempt = 0
        penaltyKubbs = 0
        neighborKubbs = 0
        kubbsClearedFirstThrow = 0
        batonsUsed = 0
        misses = 0
        isComplete = false
        batonThrows = []
    }
}

struct InkastBatonThrowData: Identifiable, Codable {
    let id: String
    let isHit: Bool
    let kubbsHit: Int
    let throwNumber: Int
    let timestamp: Date
    
    init(id: String = UUID().uuidString, 
         isHit: Bool, 
         kubbsHit: Int, 
         throwNumber: Int) {
        self.id = id
        self.isHit = isHit
        self.kubbsHit = kubbsHit
        self.throwNumber = throwNumber
        self.timestamp = Date()
    }
}
