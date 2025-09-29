//
//  TrainingMode.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 9/23/25.
//

import Foundation

enum TrainingMode: String, CaseIterable {
    case eightMeter = "8 Meter"
    case baseballKubb = "Baseball Kubb"
    case inkastBlast = "Inkast & Blast"
    case fullGameSim = "Full Game Sim"
    
    var isAvailable: Bool {
        switch self {
        case .eightMeter, .baseballKubb, .inkastBlast:
            return true
        case .fullGameSim:
            return false
        }
    }
    
    var description: String {
        switch self {
        case .eightMeter:
            return "Practice your 8-meter throws with target tracking"
        case .baseballKubb:
            return "Baseball-style Kubb game with innings and scoring"
        case .inkastBlast:
            return "Practice inkast and blast techniques with various game phases"
        case .fullGameSim:
            return "Coming Soon - Full game simulation training"
        }
    }
    
    var icon: String {
        switch self {
        case .eightMeter:
            return "target"
        case .baseballKubb:
            return "baseball_kubb"
        case .inkastBlast:
            return "inkastblast"
        case .fullGameSim:
            return "king"
        }
    }
}
