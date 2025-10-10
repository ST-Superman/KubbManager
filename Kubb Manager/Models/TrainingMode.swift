//
//  TrainingMode.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 9/23/25.
//

import Foundation

// MARK: - Training Mode Enumeration
// This enum defines the different training modes available in the app
// Each mode represents a different type of kubb practice session

enum TrainingMode: String, CaseIterable {
    case eightMeter = "8 Meter"        // 8-meter target practice mode
    case inkastBlast = "Inkast & Blast" // Inkast and blast technique practice
    case fullGameSim = "Full Game Sim"  // Full game simulation (coming soon)
    
    /// Determines if this training mode is currently available to users
    /// Used to show/hide training options in the UI
    var isAvailable: Bool {
        switch self {
        case .eightMeter, .inkastBlast, .fullGameSim:
            // These modes are fully implemented and available
            return true
        }
    }
    
    /// Human-readable description of what this training mode does
    /// Displayed in the UI to help users understand each training option
    var description: String {
        switch self {
        case .eightMeter:
            return "Practice your 8-meter throws with target tracking"
        case .inkastBlast:
            return "Practice inkast and blast techniques with various game phases"
        case .fullGameSim:
            return "Full game simulation with inkast, blast, and 8-meter phases"
        }
    }
    
    /// SF Symbol icon name for this training mode
    /// Used in the UI to visually represent each training mode
    var icon: String {
        switch self {
        case .eightMeter:
            return "target"        // Target icon for 8-meter practice
        case .inkastBlast:
            return "inkastblast"   // Custom icon for inkast/blast practice
        case .fullGameSim:
            return "king"          // King icon for full game simulation
        }
    }
}
