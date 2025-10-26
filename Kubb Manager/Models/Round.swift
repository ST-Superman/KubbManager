//
//  Round.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 9/23/25.
//

import Foundation

// MARK: - Round Data Model
// This struct represents a single round within a practice session
// A round consists of up to 6 baton throws (5 regular + 1 king throw if all 5 hit)

struct Round: Identifiable, Codable, Equatable {
    // MARK: - Core Properties
    let id: String              // Unique identifier for this round
    let roundNumber: Int        // Which round this is (1, 2, 3, etc.)
    var batonThrows: [BatonThrow] = []  // Array of baton throws in this round
    var isComplete: Bool = false         // Whether this round is finished
    
    // MARK: - Initialization
    
    /// Creates a new round with the specified number
    /// - Parameters:
    ///   - id: Unique identifier (auto-generated if not provided)
    ///   - roundNumber: The round number (1, 2, 3, etc.)
    init(id: String = UUID().uuidString, roundNumber: Int) {
        self.id = id
        self.roundNumber = roundNumber
    }
    
    // MARK: - Computed Properties
    
    /// Total number of baton throws in this round
    var totalBatonThrows: Int {
        return batonThrows.count
    }
    
    /// Number of successful hits in this round
    var hits: Int {
        return batonThrows.filter { $0.isHit }.count
    }
    
    /// Number of missed throws in this round
    var misses: Int {
        return batonThrows.filter { !$0.isHit }.count
    }
    
    /// Hit accuracy percentage for this round (0.0 to 1.0)
    var accuracy: Double {
        guard totalBatonThrows > 0 else { return 0.0 }
        return Double(hits) / Double(totalBatonThrows)
    }
    
    /// Total kubb pieces knocked down in this round
    /// In kubb, each hit knocks down one kubb (including king hits)
    var kubbsKnockedDown: Int {
        return hits
    }
    
    /// Whether this round achieved a baseline clear (5 or more hits)
    /// A baseline clear allows a king throw attempt
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
    
    var kingThrowAttempts: Int {
        return kingThrows.count
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

    /// Removes the last baton throw from the round
    /// Returns the removed throw, or nil if there were no throws to undo
    @discardableResult
    mutating func undoLastThrow() -> BatonThrow? {
        guard !batonThrows.isEmpty else { return nil }

        let removedThrow = batonThrows.removeLast()

        // Update completion status - round is no longer complete if we undid a throw
        isComplete = isRoundComplete

        return removedThrow
    }

    // MARK: - Kubb State Helpers (for backward compatibility)
    
    func kubbState(at index: Int) -> Bool {
        // Return true if the kubb at this position was hit
        return index < hits
    }
}

// MARK: - Baton Throw Data Model
// This struct represents a single baton throw within a round
// It tracks whether the throw was successful and what type of throw it was

struct BatonThrow: Identifiable, Codable, Equatable {
    // MARK: - Core Properties
    let id: String          // Unique identifier for this throw
    let isHit: Bool         // Whether this throw was successful (hit a kubb/king)
    let throwType: ThrowType // Type of throw (regular kubb throw or king throw)
    let throwNumber: Int     // Which throw this was in the round (1-6)
    let timestamp: Date     // When this throw was recorded
    
    // MARK: - Throw Type Enumeration
    // Defines the different types of throws in kubb
    enum ThrowType: String, Codable, CaseIterable {
        case kubb = "kubb"  // Regular throw at kubb pieces
        case king = "king"  // Throw at the king piece (6th throw after baseline clear)
    }
    
    // MARK: - Initialization
    
    /// Creates a new baton throw record
    /// - Parameters:
    ///   - id: Unique identifier (auto-generated if not provided)
    ///   - isHit: Whether the throw was successful
    ///   - throwType: Type of throw (kubb or king)
    ///   - throwNumber: Which throw this was in the round
    init(id: String = UUID().uuidString, isHit: Bool, throwType: ThrowType, throwNumber: Int) {
        self.id = id
        self.isHit = isHit
        self.throwType = throwType
        self.throwNumber = throwNumber
        self.timestamp = Date()  // Record when this throw was made
    }
}
