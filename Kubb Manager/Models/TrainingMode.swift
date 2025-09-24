//
//  TrainingMode.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 9/23/25.
//

import Foundation

enum TrainingMode: String, CaseIterable {
    case eightMeter = "8 Meter"
    case inkastBlast = "Inkast & Blast"
    case fullGameSim = "Full Game Sim"
    
    var isAvailable: Bool {
        switch self {
        case .eightMeter:
            return true
        case .inkastBlast, .fullGameSim:
            return false
        }
    }
    
    var description: String {
        switch self {
        case .eightMeter:
            return "Practice your 8-meter throws with target tracking"
        case .inkastBlast:
            return "Coming Soon - Practice inkast and blast techniques"
        case .fullGameSim:
            return "Coming Soon - Full game simulation training"
        }
    }
    
    var icon: String {
        switch self {
        case .eightMeter:
            return "target"
        case .inkastBlast:
            return "inkastblast"
        case .fullGameSim:
            return "king"
        }
    }
}
