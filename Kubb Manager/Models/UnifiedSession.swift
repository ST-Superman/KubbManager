//
//  UnifiedSession.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 1/15/25.
//

import Foundation

enum SessionType: String, CaseIterable {
    case practice = "8M Training"
    case inkastBlast = "Inkast & Blast"
    case baseballKubb = "Baseball Kubb"
    
    var color: Color {
        switch self {
        case .practice:
            return .blue
        case .inkastBlast:
            return .green
        case .baseballKubb:
            return .purple
        }
    }
    
    var icon: String {
        switch self {
        case .practice:
            return "target"
        case .inkastBlast:
            return "bolt.fill"
        case .baseballKubb:
            return "baseball"
        }
    }
}

enum UnifiedSession: Identifiable {
    case practice(PracticeSession)
    case inkastBlast(InkastBlastSessionData)
    case baseballKubb(BaseballKubbSession)
    
    var id: String {
        switch self {
        case .practice(let session):
            return session.id
        case .inkastBlast(let session):
            return session.id
        case .baseballKubb(let session):
            return session.id
        }
    }
    
    var date: Date {
        switch self {
        case .practice(let session):
            return session.date
        case .inkastBlast(let session):
            return session.date
        case .baseballKubb(let session):
            return session.date
        }
    }
    
    var sessionType: SessionType {
        switch self {
        case .practice:
            return .practice
        case .inkastBlast:
            return .inkastBlast
        case .baseballKubb:
            return .baseballKubb
        }
    }
    
    var title: String {
        switch self {
        case .practice:
            return "8M Training Session"
        case .inkastBlast(let session):
            return "Inkast & Blast - \(session.gamePhase.rawValue)"
        case .baseballKubb(let session):
            return "\(session.awayTeam) vs \(session.homeTeam)"
        }
    }
    
    var subtitle: String {
        switch self {
        case .practice(let session):
            return "Target: \(session.target) kubbs"
        case .inkastBlast(let session):
            return "\(session.totalRounds) rounds"
        case .baseballKubb(let session):
            return "Inning \(session.currentInning)\(session.isTop ? " (Top)" : " (Bottom)")"
        }
    }
    
    var isComplete: Bool {
        switch self {
        case .practice(let session):
            return session.isComplete
        case .inkastBlast(let session):
            return session.isComplete
        case .baseballKubb(let session):
            return session.isComplete
        }
    }
    
    var duration: TimeInterval? {
        switch self {
        case .practice(let session):
            if let endTime = session.endTime {
                return endTime.timeIntervalSince(session.startTime)
            }
            return nil
        case .inkastBlast(let session):
            if let endTime = session.endTime {
                return endTime.timeIntervalSince(session.startTime)
            }
            return nil
        case .baseballKubb(let session):
            // Estimate duration based on innings played
            return Double(session.currentInning) * 10 * 60 // 10 minutes per inning
        }
    }
    
    var primaryStat: String {
        switch self {
        case .practice(let session):
            return "\(session.totalBatons)/\(session.target)"
        case .inkastBlast(let session):
            return "\(session.totalInkastKubbs) kubbs"
        case .baseballKubb(let session):
            return "\(session.awayScore)-\(session.homeScore)"
        }
    }
    
    var secondaryStat: String {
        switch self {
        case .practice(let session):
            return String(format: "%.1f%%", session.accuracy * 100)
        case .inkastBlast(let session):
            return "\(session.totalBatonsUsed) batons"
        case .baseballKubb(let session):
            return "\(session.batonCount) batons"
        }
    }
    
    var accuracy: Double? {
        switch self {
        case .practice(let session):
            return session.accuracy
        case .inkastBlast(let session):
            return session.totalInkastKubbs > 0 ? Double(session.totalInkastKubbs) / Double(session.totalBatonsUsed) : nil
        case .baseballKubb(let session):
            return session.batonCount > 0 ? Double(session.userScore) / Double(session.batonCount) : nil
        }
    }
}

import SwiftUI
