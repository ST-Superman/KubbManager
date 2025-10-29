//
//  WatchCommunication.swift
//  Kubb Manager
//
//  Created by AI Assistant on 10/8/25.
//

import Foundation

// MARK: - Watch Input Types

/// Defines the type of input the watch should request from the user
enum WatchInputType: Codable {
    case batonThrow(context: BatonThrowContext)
    case inkast(context: InkastContext)
}

// MARK: - Baton Throw Context

/// Context information for a baton throw input request
struct BatonThrowContext: Codable, Equatable {
    /// Text to display to user (e.g., "Baton 1 of 6", "Throw at field kubbs")
    let promptText: String
    
    /// Whether to allow user to specify number of kubbs hit
    let allowKubbCount: Bool
    
    /// Maximum number of kubbs that can be hit (nil = no limit)
    let maxKubbs: Int?
    
    /// Current baton number in the sequence
    let batonNumber: Int?
    
    /// Total batons available in this phase
    let totalBatons: Int?
    
    init(promptText: String, 
         allowKubbCount: Bool = true, 
         maxKubbs: Int? = nil,
         batonNumber: Int? = nil,
         totalBatons: Int? = nil) {
        self.promptText = promptText
        self.allowKubbCount = allowKubbCount
        self.maxKubbs = maxKubbs
        self.batonNumber = batonNumber
        self.totalBatons = totalBatons
    }
}

// MARK: - Inkast Context

/// Context information for an inkast input request
struct InkastContext: Codable, Equatable {
    /// Text to display to user (e.g., "Out of bounds (1st)?", "Neighbors?")
    let promptText: String
    
    /// Maximum valid count for this input
    let maxCount: Int
    
    /// Type of inkast input being requested
    let inkastType: InkastInputType
    
    init(promptText: String, maxCount: Int, inkastType: InkastInputType) {
        self.promptText = promptText
        self.maxCount = maxCount
        self.inkastType = inkastType
    }
}

/// Types of inkast inputs
enum InkastInputType: String, Codable {
    case firstAttemptOut = "first_attempt_out"
    case secondAttemptOut = "second_attempt_out"
    case neighbors = "neighbors"
}

// MARK: - Watch Results

/// Result from a baton throw input on the watch
struct BatonThrowResult: Codable {
    let isHit: Bool
    let kubbsHit: Int
    let timestamp: Date
    
    init(isHit: Bool, kubbsHit: Int, timestamp: Date = Date()) {
        self.isHit = isHit
        self.kubbsHit = kubbsHit
        self.timestamp = timestamp
    }
}

/// Result from an inkast input on the watch
struct InkastResult: Codable {
    let count: Int
    let inkastType: InkastInputType
    let timestamp: Date
    
    init(count: Int, inkastType: InkastInputType, timestamp: Date = Date()) {
        self.count = count
        self.inkastType = inkastType
        self.timestamp = timestamp
    }
}

// MARK: - Watch Communication Messages

/// Messages sent between phone and watch
enum WatchMessage: String, Codable {
    // Phone -> Watch
    case sessionStarted = "session_started"
    case sessionEnded = "session_ended"
    case requestInput = "request_input"
    case inputReceived = "input_received"
    case sessionStateUpdate = "session_state_update"
    case enableWatchMode = "enable_watch_mode"
    case disableWatchMode = "disable_watch_mode"
    
    // Watch -> Phone
    case batonThrowResult = "baton_throw_result"
    case inkastResult = "inkast_result"
    case requestSessionState = "request_session_state"
    case nextPhase = "next_phase"
    case nextRound = "next_round"
    case endSession = "end_session"
    
    // Bidirectional
    case error = "error"
    case acknowledgment = "acknowledgment"
}

// MARK: - Session State for Watch Display

/// Simplified session state to display on watch
struct WatchSessionState: Codable, Equatable {
    let sessionType: String  // "8M Training", "Inkast & Blast", etc.
    let isActive: Bool
    let currentRound: Int?
    let totalRounds: Int?
    let currentPhase: String?  // "Inkast", "Blasting", "8-Meter", etc.
    let isWatchMode: Bool  // Whether watch is driving the session flow
    let targetBatons: Int?  // Target number of batons for session (for 8M Training)
    let currentBatons: Int?  // Current number of batons thrown (for 8M Training)
    let isTargetReached: Bool  // Whether the target has been reached
    let hasALine: Bool?  // Whether current round has A-Line advantage (Full Game Sim only)
    let currentAttackingTeam: Int?  // Which team is attacking: 1 or 2 (Full Game Sim only)
    
    init(sessionType: String, 
         isActive: Bool, 
         currentRound: Int? = nil, 
         totalRounds: Int? = nil,
         currentPhase: String? = nil,
         isWatchMode: Bool = false,
         targetBatons: Int? = nil,
         currentBatons: Int? = nil,
         isTargetReached: Bool = false,
         hasALine: Bool? = nil,
         currentAttackingTeam: Int? = nil) {
        self.sessionType = sessionType
        self.isActive = isActive
        self.currentRound = currentRound
        self.totalRounds = totalRounds
        self.currentPhase = currentPhase
        self.isWatchMode = isWatchMode
        self.targetBatons = targetBatons
        self.currentBatons = currentBatons
        self.isTargetReached = isTargetReached
        self.hasALine = hasALine
        self.currentAttackingTeam = currentAttackingTeam
    }
}

// MARK: - Watch Communication Protocol

/// Protocol for handling watch communication
protocol WatchCommunicationDelegate: AnyObject {
    /// Called when a baton throw result is received from the watch
    func didReceiveBatonThrowResult(_ result: BatonThrowResult)
    
    /// Called when an inkast result is received from the watch
    func didReceiveInkastResult(_ result: InkastResult)
    
    /// Called when watch requests current session state
    func didRequestSessionState()
    
    /// Called when watch connectivity state changes
    func watchConnectivityDidChange(isReachable: Bool)
    
    // MARK: - Watch Mode Support
    
    /// Called when watch requests to advance to next phase
    func didRequestNextPhase()
    
    /// Called when watch requests to start next round
    func didRequestNextRound()
    
    /// Called when watch requests to end session
    func didRequestEndSession()
}

// MARK: - Helper Extensions

extension WatchInputType {
    /// Converts the input type to a dictionary for WatchConnectivity
    func toDictionary() -> [String: Any] {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(self),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        return json
    }
    
    /// Creates an input type from a dictionary
    static func fromDictionary(_ dict: [String: Any]) -> WatchInputType? {
        guard let data = try? JSONSerialization.data(withJSONObject: dict),
              let inputType = try? JSONDecoder().decode(WatchInputType.self, from: data) else {
            return nil
        }
        return inputType
    }
}

extension BatonThrowResult {
    /// Converts the result to a dictionary for WatchConnectivity
    func toDictionary() -> [String: Any] {
        return [
            "isHit": isHit,
            "kubbsHit": kubbsHit,
            "timestamp": timestamp.timeIntervalSince1970
        ]
    }
    
    /// Creates a result from a dictionary
    static func fromDictionary(_ dict: [String: Any]) -> BatonThrowResult? {
        guard let isHit = dict["isHit"] as? Bool,
              let kubbsHit = dict["kubbsHit"] as? Int,
              let timestampInterval = dict["timestamp"] as? TimeInterval else {
            return nil
        }
        return BatonThrowResult(
            isHit: isHit,
            kubbsHit: kubbsHit,
            timestamp: Date(timeIntervalSince1970: timestampInterval)
        )
    }
}

extension InkastResult {
    /// Converts the result to a dictionary for WatchConnectivity
    func toDictionary() -> [String: Any] {
        return [
            "count": count,
            "inkastType": inkastType.rawValue,
            "timestamp": timestamp.timeIntervalSince1970
        ]
    }
    
    /// Creates a result from a dictionary
    static func fromDictionary(_ dict: [String: Any]) -> InkastResult? {
        guard let count = dict["count"] as? Int,
              let inkastTypeString = dict["inkastType"] as? String,
              let inkastType = InkastInputType(rawValue: inkastTypeString),
              let timestampInterval = dict["timestamp"] as? TimeInterval else {
            return nil
        }
        return InkastResult(
            count: count,
            inkastType: inkastType,
            timestamp: Date(timeIntervalSince1970: timestampInterval)
        )
    }
}

extension WatchSessionState {
    /// Converts the session state to a dictionary for WatchConnectivity
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "sessionType": sessionType,
            "isActive": isActive,
            "isWatchMode": isWatchMode,
            "isTargetReached": isTargetReached
        ]
        
        if let currentRound = currentRound {
            dict["currentRound"] = currentRound
        }
        if let totalRounds = totalRounds {
            dict["totalRounds"] = totalRounds
        }
        if let currentPhase = currentPhase {
            dict["currentPhase"] = currentPhase
        }
        if let targetBatons = targetBatons {
            dict["targetBatons"] = targetBatons
        }
        if let currentBatons = currentBatons {
            dict["currentBatons"] = currentBatons
        }
        
        return dict
    }
    
    /// Creates a session state from a dictionary
    static func fromDictionary(_ dict: [String: Any]) -> WatchSessionState? {
        guard let sessionType = dict["sessionType"] as? String,
              let isActive = dict["isActive"] as? Bool else {
            return nil
        }
        
        return WatchSessionState(
            sessionType: sessionType,
            isActive: isActive,
            currentRound: dict["currentRound"] as? Int,
            totalRounds: dict["totalRounds"] as? Int,
            currentPhase: dict["currentPhase"] as? String,
            isWatchMode: dict["isWatchMode"] as? Bool ?? false,
            targetBatons: dict["targetBatons"] as? Int,
            currentBatons: dict["currentBatons"] as? Int,
            isTargetReached: dict["isTargetReached"] as? Bool ?? false
        )
    }
}
