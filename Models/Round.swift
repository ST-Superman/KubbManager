//
//  Round.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 9/23/25.
//

import Foundation

struct Round: Identifiable, Codable {
    let id: String
    let roundNumber: Int
    var batonThrows: [BatonThrow] = []
    var isComplete: Bool = false
    
    init(id: String = UUID().uuidString, roundNumber: Int) {
        self.id = id
        self.roundNumber = roundNumber
    }
    
    // MARK: - Computed Properties
    
    var totalBatonThrows: Int {
        return batonThrows.count
    }
    
    var hits: Int {
        return batonThrows.filter { $0.isHit }.count
    }
    
    var misses: Int {
        return batonThrows.filter { !$0.isHit }.count
    }
    
    var accuracy: Double {
        guard totalBatonThrows > 0 else { return 0.0 }
        return Double(hits) / Double(totalBatonThrows)
    }
    
    var kubbsKnockedDown: Int {
        // In kubb, each hit knocks down one kubb (including king hits)
        return hits
    }
    
    var hasBaselineClear: Bool {
        return hits >= 5
    }
    
    var kingThrows: [BatonThrow] {
        // King throws are the 6th throw in a round (if there are 5 hits)
        return batonThrows.filter { $0.throwType == .king }
    }
    
    var kingThrowsCount: Int {
        return kingThrows.count
    }
    
    var kingHits: Int {
        return kingThrows.filter { $0.isHit }.count
    }
    
    var isRoundComplete: Bool {
        return totalBatonThrows >= 6
    }
    
    // MARK: - Round Management
    
    mutating func addBatonThrow(isHit: Bool, throwType: BatonThrow.ThrowType = .kubb) {
        let batonThrow = BatonThrow(
            isHit: isHit,
            throwType: throwType,
            throwNumber: totalBatonThrows + 1
        )
        batonThrows.append(batonThrow)
        
        // Check if round is complete
        if isRoundComplete {
            isComplete = true
        }
    }
    
    mutating func resetRound() {
        batonThrows = []
        isComplete = false
    }
    
    // MARK: - Kubb State Helpers (for backward compatibility)
    
    func kubbState(at index: Int) -> Bool {
        // Return true if the kubb at this position was hit
        return index < hits
    }
}

struct BatonThrow: Identifiable, Codable {
    let id: String
    let isHit: Bool
    let throwType: ThrowType
    let throwNumber: Int
    let timestamp: Date
    
    enum ThrowType: String, Codable, CaseIterable {
        case kubb = "kubb"
        case king = "king"
    }
    
    init(id: String = UUID().uuidString, isHit: Bool, throwType: ThrowType, throwNumber: Int) {
        self.id = id
        self.isHit = isHit
        self.throwType = throwType
        self.throwNumber = throwNumber
        self.timestamp = Date()
    }
}
