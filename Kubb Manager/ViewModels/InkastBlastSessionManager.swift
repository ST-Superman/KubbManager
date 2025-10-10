//
//  InkastBlastSessionManager.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 1/15/25.
//

import Foundation
import CoreData
import CloudKit

@MainActor
class InkastBlastSessionManager: ObservableObject {
    @Published var currentSession: InkastBlastSessionData?
    @Published var currentRound: InkastBlastRoundData?
    @Published var isSessionActive: Bool = false
    @Published var isPaused: Bool = false
    @Published var selectedGamePhase: GamePhase = .early
    
    // Round state tracking
    @Published var currentRoundNumber: Int = 1
    @Published var currentInkastKubbs: Int = 0
    @Published var roundPhase: RoundPhase = .inkast
    @Published var kubbsOutFirstAttempt: Int = 0
    @Published var kubbsOutSecondAttempt: Int = 0
    @Published var neighborKubbs: Int = 0
    @Published var knockedDownKubbs: Set<Int> = [] // Track which specific kubbs are knocked down
    
    // Session statistics
    @Published var sessionStats: SessionStats = SessionStats()
    
    private let persistenceController: PersistenceController
    private let cloudKitManager: CloudKitManager
    
    enum RoundPhase {
        case inkast
        case firstAttemptResults
        case secondAttempt
        case secondAttemptResults
        case neighborCheck
        case blasting
        case roundComplete
    }
    
    struct SessionStats {
        var totalRounds: Int = 0
        var totalInkastKubbs: Int = 0
        var totalKubbsClearedFirstThrow: Int = 0
        var totalBatonsUsed: Int = 0
        var totalPenaltyKubbs: Int = 0
        var totalNeighborKubbs: Int = 0
        var totalMisses: Int = 0
        var averageKubbsPerRound: Double = 0.0
        var averageBatonsPerRound: Double = 0.0
        var averageKubbsPerBaton: Double = 0.0
        var penaltyRate: Double = 0.0
        var neighborRate: Double = 0.0
    }
    
    init(persistenceController: PersistenceController, cloudKitManager: CloudKitManager) {
        self.persistenceController = persistenceController
        self.cloudKitManager = cloudKitManager
        loadIncompleteSession()
    }
    
    // MARK: - Session Management
    
    func startNewSession(gamePhase: GamePhase) {
        selectedGamePhase = gamePhase
        currentSession = InkastBlastSessionData(gamePhase: gamePhase)
        currentRoundNumber = 1
        roundPhase = .inkast
        isSessionActive = true
        isPaused = false
        generateNewRound()
        
        // Setup watch connectivity and notify watch
        setupWatchConnectivity()
        notifyWatchSessionStarted()
        sendSessionStateToWatch()
    }
    
    func pauseSession() {
        guard var session = currentSession else { return }
        session.pauseSession()
        currentSession = session
        isPaused = true
        saveSession()
    }
    
    func resumeSession() {
        guard var session = currentSession else { return }
        session.resumeSession()
        currentSession = session
        isPaused = false
        
        // Setup watch connectivity when resuming
        setupWatchConnectivity()
        notifyWatchSessionStarted()
        sendSessionStateToWatch()
        
        saveSession()
    }
    
    func endSession() {
        guard var session = currentSession else { return }
        session.completeSession()
        currentSession = session
        isSessionActive = false
        isPaused = false
        saveSession()
        updateSessionStats()
    }
    
    // MARK: - Round Management
    
    func generateNewRound() {
        guard let session = currentSession else { return }
        
        let kubbCount = generateRandomKubbCount(for: session.gamePhase)
        currentInkastKubbs = kubbCount
        currentRound = InkastBlastRoundData(roundNumber: currentRoundNumber, inkastKubbs: kubbCount)
        roundPhase = .inkast
        kubbsOutFirstAttempt = 0
        kubbsOutSecondAttempt = 0
        neighborKubbs = 0
        knockedDownKubbs = [] // Reset knocked down kubbs for new round
    }
    
    private func generateRandomKubbCount(for gamePhase: GamePhase) -> Int {
        let range = gamePhase.kubbRange
        return Int.random(in: range)
    }
    
    func recordFirstAttemptResults(outOfBounds: Int) {
        kubbsOutFirstAttempt = outOfBounds
        roundPhase = outOfBounds > 0 ? .secondAttempt : .neighborCheck
    }
    
    func recordSecondAttemptResults(outOfBounds: Int) {
        kubbsOutSecondAttempt = outOfBounds
        roundPhase = .neighborCheck
    }
    
    func recordNeighborKubbs(count: Int) {
        neighborKubbs = count
        roundPhase = .blasting
    }
    
    func addBatonThrow(isHit: Bool, kubbsHit: Int = 0) {
        guard var round = currentRound else { return }
        
        // Update the knocked down kubbs set for visual tracking
        if isHit {
            // Add the next kubbs to the knocked down set
            let totalKubbs = round.inkastKubbs - round.penaltyKubbs
            let startIndex = knockedDownKubbs.count
            let endIndex = min(startIndex + kubbsHit, totalKubbs)
            
            for i in startIndex..<endIndex {
                knockedDownKubbs.insert(i)
            }
        }
        
        round.addBatonThrow(isHit: isHit, kubbsHit: kubbsHit)
        currentRound = round
        
        // Check if round is complete
        if round.isComplete {
            completeCurrentRound()
        }
    }
    
    func addBatonThrowWithKubbs(isHit: Bool, newlyKnockedDownKubbs: Set<Int>) {
        guard var round = currentRound else { return }
        
        // Update the knocked down kubbs set
        if isHit {
            knockedDownKubbs.formUnion(newlyKnockedDownKubbs)
        }
        
        // Add the baton throw with the count of newly knocked down kubbs
        round.addBatonThrow(isHit: isHit, kubbsHit: newlyKnockedDownKubbs.count)
        currentRound = round
        
        // Check if round is complete
        if round.isComplete {
            completeCurrentRound()
        }
    }
    
    
    func completeCurrentRound() {
        guard var session = currentSession,
              var round = currentRound else { return }
        
        // Record inkast results
        round.recordInkastResults(
            firstAttemptOut: kubbsOutFirstAttempt,
            secondAttemptOut: kubbsOutSecondAttempt,
            neighbors: neighborKubbs
        )
        
        // Add round to session
        session.addRound(round)
        currentSession = session
        
        // Update round tracking
        currentRoundNumber += 1
        roundPhase = .roundComplete
        
        // Save session
        saveSession()
        updateSessionStats()
    }
    
    func startNextRound() {
        generateNewRound()
    }
    
    // MARK: - Data Persistence
    
    private func saveSession() {
        guard let session = currentSession else { return }
        
        // Save to Core Data
        let context = persistenceController.container.viewContext
        
        // Check if session already exists
        let fetchRequest: NSFetchRequest<InkastBlastSession> = InkastBlastSession.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", session.id)
        
        do {
            let existingSessions = try context.fetch(fetchRequest)
            let coreDataSession: InkastBlastSession
            
            if let existing = existingSessions.first {
                // Update existing session
                coreDataSession = existing
                coreDataSession.date = session.date
                coreDataSession.gamePhase = session.gamePhase.rawValue
                coreDataSession.startTime = session.startTime
                coreDataSession.endTime = session.endTime
                coreDataSession.isComplete = session.isComplete
                coreDataSession.isPaused = session.isPaused
                coreDataSession.totalRounds = Int16(session.totalRounds)
                coreDataSession.totalInkastKubbs = Int16(session.totalInkastKubbs)
                coreDataSession.totalKubbsClearedFirstThrow = Int16(session.totalKubbsClearedFirstThrow)
                coreDataSession.totalBatonsUsed = Int16(session.totalBatonsUsed)
                coreDataSession.totalPenaltyKubbs = Int16(session.totalPenaltyKubbs)
                coreDataSession.totalNeighborKubbs = Int16(session.totalNeighborKubbs)
                coreDataSession.totalMisses = Int16(session.totalMisses)
                coreDataSession.modifiedAt = session.modifiedAt
            } else {
                // Create new session
                coreDataSession = InkastBlastSession(context: context)
                coreDataSession.id = session.id
                coreDataSession.date = session.date
                coreDataSession.gamePhase = session.gamePhase.rawValue
                coreDataSession.startTime = session.startTime
                coreDataSession.endTime = session.endTime
                coreDataSession.isComplete = session.isComplete
                coreDataSession.isPaused = session.isPaused
                coreDataSession.totalRounds = Int16(session.totalRounds)
                coreDataSession.totalInkastKubbs = Int16(session.totalInkastKubbs)
                coreDataSession.totalKubbsClearedFirstThrow = Int16(session.totalKubbsClearedFirstThrow)
                coreDataSession.totalBatonsUsed = Int16(session.totalBatonsUsed)
                coreDataSession.totalPenaltyKubbs = Int16(session.totalPenaltyKubbs)
                coreDataSession.totalNeighborKubbs = Int16(session.totalNeighborKubbs)
                coreDataSession.totalMisses = Int16(session.totalMisses)
                coreDataSession.createdAt = session.createdAt
                coreDataSession.modifiedAt = session.modifiedAt
            }
            
            try context.save()
            
            // Sync to CloudKit
            Task {
                await cloudKitManager.saveInkastBlastSession(session)
            }
            
        } catch {
            print("Error saving InkastBlastSession: \(error)")
        }
    }
    
    private func loadIncompleteSession() {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<InkastBlastSession> = InkastBlastSession.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isComplete == NO AND isPaused == YES")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \InkastBlastSession.modifiedAt, ascending: false)]
        fetchRequest.fetchLimit = 1
        
        do {
            let sessions = try context.fetch(fetchRequest)
            if let session = sessions.first {
                // Convert Core Data session to struct
                let sessionId = session.id ?? UUID().uuidString
                let sessionDate = session.date ?? Date()
                let gamePhase = GamePhase(rawValue: session.gamePhase ?? "Early Game") ?? .early
                let startTime = session.startTime ?? Date()
                let modifiedAt = session.modifiedAt ?? Date()
                
                var sessionData = InkastBlastSessionData(
                    id: sessionId,
                    date: sessionDate,
                    gamePhase: gamePhase,
                    startTime: startTime
                )
                
                // Set additional properties
                sessionData.endTime = session.endTime
                sessionData.isComplete = session.isComplete
                sessionData.isPaused = session.isPaused
                sessionData.totalRounds = Int(session.totalRounds)
                sessionData.totalInkastKubbs = Int(session.totalInkastKubbs)
                sessionData.totalKubbsClearedFirstThrow = Int(session.totalKubbsClearedFirstThrow)
                sessionData.totalBatonsUsed = Int(session.totalBatonsUsed)
                sessionData.totalPenaltyKubbs = Int(session.totalPenaltyKubbs)
                sessionData.totalNeighborKubbs = Int(session.totalNeighborKubbs)
                sessionData.totalMisses = Int(session.totalMisses)
                sessionData.rounds = [] // TODO: Load rounds from Core Data
                sessionData.modifiedAt = modifiedAt
                
                currentSession = sessionData
                isSessionActive = true
                isPaused = true
                
                // Don't setup watch connectivity yet - wait until user actually resumes
                // setupWatchConnectivity() will be called in resumeSession()
                
                updateSessionStats()
            }
        } catch {
            print("Error loading incomplete session: \(error)")
        }
    }
    
    private func updateSessionStats() {
        guard let session = currentSession else { return }
        
        sessionStats.totalRounds = session.totalRounds
        sessionStats.totalInkastKubbs = session.totalInkastKubbs
        sessionStats.totalKubbsClearedFirstThrow = session.totalKubbsClearedFirstThrow
        sessionStats.totalBatonsUsed = session.totalBatonsUsed
        sessionStats.totalPenaltyKubbs = session.totalPenaltyKubbs
        sessionStats.totalNeighborKubbs = session.totalNeighborKubbs
        sessionStats.totalMisses = session.totalMisses
        sessionStats.averageKubbsPerRound = session.averageKubbsPerRound
        sessionStats.averageBatonsPerRound = session.averageBatonsPerRound
        sessionStats.averageKubbsPerBaton = session.averageKubbsPerBaton
        sessionStats.penaltyRate = session.penaltyRate
        sessionStats.neighborRate = session.neighborRate
    }
}
