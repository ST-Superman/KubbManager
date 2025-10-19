//
//  FullGameSimSessionManager.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 1/15/25.
//

import Foundation
import CoreData
import CloudKit

@MainActor
class FullGameSimSessionManager: ObservableObject {
    @Published var currentSession: FullGameSimSessionStruct?
    @Published var currentRound: FullGameSimRoundStruct?
    @Published var isSessionActive: Bool = false
    @Published var isPaused: Bool = false
    
    // Round state tracking
    @Published var currentRoundNumber: Int = 1
    @Published var currentPhase: FullGamePhase = .attacking
    @Published var kubbsOutFirstAttempt: Int = 0
    @Published var kubbsOutSecondAttempt: Int = 0
    @Published var neighborKubbs: Int = 0
    @Published var knockedDownKubbs: Set<Int> = [] // Track which specific kubbs are knocked down
    
    // Session statistics
    @Published var sessionStats: SessionStats = SessionStats()
    
    private let persistenceController: PersistenceController
    private let cloudKitManager: CloudKitManager
    
    struct SessionStats {
        var totalRounds: Int = 0
        var totalInkastKubbs: Int = 0
        var totalKubbsClearedFirstThrow: Int = 0
        var totalBatonsUsed: Int = 0
        var totalPenaltyKubbs: Int = 0
        var totalNeighborKubbs: Int = 0
        var totalMisses: Int = 0
        var totalEightMeterHits: Int = 0
        var totalEightMeterBatons: Int = 0
        var averageKubbsPerRound: Double = 0.0
        var averageBatonsPerRound: Double = 0.0
        var averageKubbsPerBaton: Double = 0.0
        var penaltyRate: Double = 0.0
        var neighborRate: Double = 0.0
        var eightMeterAccuracy: Double = 0.0
    }
    
    init(persistenceController: PersistenceController, cloudKitManager: CloudKitManager) {
        self.persistenceController = persistenceController
        self.cloudKitManager = cloudKitManager
        // Note: loadIncompleteSession is called from the view's onAppear to ensure proper timing
    }
    
    // MARK: - Incomplete Session Management
    
    func hasIncompleteSession() -> Bool {
        return currentSession != nil && !currentSession!.isComplete
    }
    
    func shouldShowRecoveryAlert() -> Bool {
        return hasIncompleteSession()
    }
    
    func resumeIncompleteSession() {
        guard var session = currentSession else { return }
        
        // Clean up incomplete round if exists
        if let lastRound = session.rounds.last, !lastRound.isComplete {
            // Remove the incomplete round - we'll start it fresh
            session.rounds.removeLast()
            currentRoundNumber = lastRound.roundNumber // Start from this round number
        } else {
            // No incomplete round, continue from next round
            currentRoundNumber = session.currentRound
        }
        
        // Set up session state
        currentSession = session
        currentPhase = session.currentPhase
        isSessionActive = true
        isPaused = false
        
        // Generate a fresh round at the current position
        generateNewRound()
        saveSession()
    }
    
    func abandonIncompleteSession() async {
        guard let session = currentSession else { return }
        
        // Delete from local storage
        LocalStorageManager.shared.deleteFullGameSimSession(session)
        
        // Delete from CloudKit
        await cloudKitManager.deleteFullGameSimSession(session)
        
        // Clear current state
        currentSession = nil
        currentRound = nil
        isSessionActive = false
        isPaused = false
        currentRoundNumber = 1
        currentPhase = .attacking
    }
    
    // MARK: - Session Management
    
    func startNewSession() {
        currentSession = FullGameSimSessionStruct()
        currentRoundNumber = 1
        currentPhase = .attacking
        isSessionActive = true
        isPaused = false
        generateNewRound()
        
        // Setup watch connectivity and notify watch
        setupWatchConnectivity()
        notifyWatchSessionStarted()
        sendSessionStateToWatch()
    }
    
    func pauseSession() {
        guard var session = currentSession else { 
            print("⚠️ pauseSession called but no current session")
            return 
        }
        print("⏸️ Pausing session: \(session.id)")
        session.pauseSession()
        currentSession = session
        isPaused = true
        print("⏸️ Session paused, now saving...")
        saveSession()
        print("⏸️ Session saved successfully")
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
        guard currentSession != nil else { return }
        
        let newRound = FullGameSimRoundStruct(roundNumber: currentRoundNumber)
        currentRound = newRound
        
        // Set initial phase based on round number
        if currentRoundNumber == 1 {
            // Round 1: Only attacking phase (8-meter only)
            currentPhase = .attacking
        } else {
            // Round 2+: Start with inkast phase
            currentPhase = .inkast
            // Set up inkast kubbs based on previous round's 8-meter hits
            generateInkastKubbs()
        }
        
        kubbsOutFirstAttempt = 0
        kubbsOutSecondAttempt = 0
        neighborKubbs = 0
        knockedDownKubbs = []
    }
    
    func nextPhase() {
        guard var session = currentSession else { return }
        
        session.nextPhase()
        currentPhase = session.currentPhase
        currentSession = session
        
        // If moving to inkast phase, generate inkast kubbs
        if currentPhase == .inkast {
            generateInkastKubbs()
        }
        
        saveSession()
    }
    
    private func generateInkastKubbs() {
        guard var round = currentRound, let session = currentSession else { return }
        
        // For round 1, no inkast kubbs needed (only 8-meter phase)
        if currentRoundNumber == 1 {
            round.inkastData.inkastKubbs = 0
            currentRound = round
            return
        }
        
        // Determine current attacking team and opponent team
        let currentTeam = session.currentAttackingTeam
        let opponentTeam = currentTeam == 1 ? 2 : 1
        
        // Check if opponent left uncleared kubbs in the previous round (which gives us A-Line)
        let opponentUnclearedKubbs = opponentTeam == 1 ? session.team1UnclearedKubbs : session.team2UnclearedKubbs
        
        // Check if current team has carried-forward uncleared kubbs from 2 rounds ago
        let carriedForwardKubbs = currentTeam == 1 ? session.team1UnclearedKubbs : session.team2UnclearedKubbs
        
        // For subsequent rounds, inkast kubbs = field kubbs + baseline kubbs knocked down in previous round
        if let previousRound = session.rounds.last {
            let fieldKubbsKnockedDown = previousRound.blastData.kubbsClearedFirstThrow
            let baselineKubbsKnockedDown = previousRound.baselineKubbsHit
            let newInkastKubbs = fieldKubbsKnockedDown + baselineKubbsKnockedDown
            
            // Total inkast kubbs = new kubbs + carried-forward kubbs from this team's last attack
            let totalInkastKubbs = newInkastKubbs + carriedForwardKubbs
            
            print("📱 Generating inkast for Round \(currentRoundNumber) - Team \(currentTeam) attacking:")
            print("   - Previous round: \(previousRound.roundNumber) (Team \(opponentTeam))")
            print("   - Field kubbs cleared by opponent: \(fieldKubbsKnockedDown)")
            print("   - Baseline kubbs hit by opponent: \(baselineKubbsKnockedDown)")
            print("   - New inkast kubbs: \(newInkastKubbs)")
            print("   - Carried-forward uncleared kubbs (from round \(currentRoundNumber - 2)): \(carriedForwardKubbs)")
            print("   - Total inkast kubbs: \(totalInkastKubbs)")
            
            round.inkastData.inkastKubbs = totalInkastKubbs
            
            // Set A-Line status if opponent left kubbs uncleared
            if opponentUnclearedKubbs > 0 {
                round.hasALine = true
                round.gamePhaseWhenALineAwarded = previousRound.gamePhase()
                print("   - ⚡ A-Line ACTIVE! Opponent left \(opponentUnclearedKubbs) kubbs (game phase: \(previousRound.gamePhase()))")
            } else {
                round.hasALine = false
                print("   - 📏 No A-Line - attack from baseline")
            }
        } else {
            // Fallback: if no previous round, use 1 kubb
            round.inkastData.inkastKubbs = 1
        }
        
        currentRound = round
    }
    
    // MARK: - Eight Meter Phase
    
    func addEightMeterBatonThrow(isHit: Bool, fromALine: Bool = false) {
        guard var round = currentRound else { return }
        
        round.eightMeterData.addBatonThrow(isHit: isHit, fromALine: fromALine)
        currentRound = round
        
        print("📱 addEightMeterBatonThrow: batonsUsed=\(round.eightMeterData.batonsUsed), limit=\(getBatonLimitForRound(round.roundNumber)), fromALine=\(fromALine)")
        
        // Check if round is complete
        if currentRoundNumber == 1 {
            // Round 1: Check if 8-meter phase is complete
            let isComplete = isEightMeterPhaseComplete(round)
            print("📱 Round 1 - isEightMeterPhaseComplete: \(isComplete)")
            if isComplete {
                completeCurrentRound()
            }
        } else {
            // Round 2+: Check if entire attacking phase is complete
            if isRoundComplete(round) {
                completeCurrentRound()
            }
        }
        
        updateSessionStats()
    }
    
    // MARK: - Inkast Phase
    
    func recordFirstAttemptResults(outOfBounds: Int) {
        kubbsOutFirstAttempt = outOfBounds
    }
    
    func recordSecondAttemptResults(outOfBounds: Int) {
        kubbsOutSecondAttempt = outOfBounds
    }
    
    func recordNeighborKubbs(count: Int) {
        neighborKubbs = count
    }
    
    func completeInkastPhase() {
        guard var round = currentRound else { return }
        
        round.inkastData.recordInkastResults(
            firstAttemptOut: kubbsOutFirstAttempt,
            secondAttemptOut: kubbsOutSecondAttempt,
            neighbors: neighborKubbs
        )
        currentRound = round
        
        // Move to attacking phase (not complete the round)
        currentPhase = .attacking
        
        saveSession()
    }
    
    // MARK: - Inkast Phase
    
    func addInkastBatonThrow(isHit: Bool, kubbsHit: Int = 0) {
        guard var round = currentRound else { return }
        
        round.inkastData.addBatonThrow(isHit: isHit, kubbsHit: kubbsHit)
        currentRound = round
        
        // Update session stats
        if let session = currentSession {
            var updatedSession = session
            updatedSession.totalBatonsUsed += 1
            if isHit {
                updatedSession.totalInkastKubbs += kubbsHit
            } else {
                updatedSession.totalMisses += 1
            }
            currentSession = updatedSession
        }
        
        // Check if inkast phase is complete
        if round.inkastData.isInkastComplete {
            completeInkastPhase()
        }
    }
    
    // MARK: - Blast Phase
    
    func addBlastBatonThrow(isHit: Bool, kubbsHit: Int = 0) {
        guard var round = currentRound else { return }
        
        // Update the knocked down kubbs set for visual tracking
        if isHit {
            let totalKubbs = round.inkastData.totalKubbsInBounds
            let startIndex = knockedDownKubbs.count
            let endIndex = min(startIndex + kubbsHit, totalKubbs)
            
            for i in startIndex..<endIndex {
                knockedDownKubbs.insert(i)
            }
        }
        
        // Blasting phase throws from A-Line if round has A-Line active
        let fromALine = round.hasALine
        round.blastData.addBatonThrow(isHit: isHit, kubbsHit: kubbsHit, fromALine: fromALine)
        currentRound = round
        
        // Check if round is complete after this baton throw
        if isRoundComplete(round) {
            completeCurrentRound()
        }
        
        updateSessionStats()
    }
    
    func addBlastBatonThrowWithFieldAndBaseline(fieldKubbsHit: Int, baselineKubbsHit: Int, kingHit: Bool) {
        guard var round = currentRound, var session = currentSession else { return }
        
        print("📱 addBlastBatonThrowWithFieldAndBaseline: field=\(fieldKubbsHit), baseline=\(baselineKubbsHit), king=\(kingHit)")
        
        // Determine which phase this baton throw belongs to based on what's being hit
        let hasFieldKubbs = fieldKubbsHit > 0
        let hasBaselineKubbs = baselineKubbsHit > 0
        let hasKingHit = kingHit
        
        // Update knocked down kubbs set for field kubbs (critical for accurate tracking!)
        if hasFieldKubbs {
            let totalKubbs = round.inkastData.totalKubbsInBounds
            let startIndex = knockedDownKubbs.count
            let endIndex = min(startIndex + fieldKubbsHit, totalKubbs)
            
            for i in startIndex..<endIndex {
                knockedDownKubbs.insert(i)
            }
        }
        
        // Determine if throwing from A-Line
        // Field kubb throws and baseline throws are from A-Line if round has A-Line active
        // EXCEPT king shots which must always be from baseline
        let fromALine = round.hasALine && !hasKingHit
        
        // Single baton throw - only count as 1 baton regardless of how many kubbs it hits
        if hasFieldKubbs {
            // Field kubbs hit - count as blast phase baton
            round.blastData.addBatonThrow(isHit: true, kubbsHit: fieldKubbsHit, fromALine: fromALine)
            print("📱 Added to blast phase: batonsUsed=\(round.blastData.batonsUsed), fromALine=\(fromALine)")
        } else if hasBaselineKubbs {
            // Only baseline kubbs hit - count as 8-meter phase baton
            round.eightMeterData.addBatonThrow(isHit: true, fromALine: fromALine)
            print("📱 Added to 8-meter phase: batonsUsed=\(round.eightMeterData.batonsUsed), fromALine=\(fromALine)")
        } else if hasKingHit {
            // Only king hit - count as 8-meter phase baton (always from baseline!)
            round.eightMeterData.addBatonThrow(isHit: true, fromALine: false)
            print("📱 Added king hit to 8-meter phase: batonsUsed=\(round.eightMeterData.batonsUsed), fromBaseline=true")
        }
        
        // Track the kubbs hit (separate from baton counting)
        if baselineKubbsHit > 0 {
            round.baselineKubbsHit += baselineKubbsHit
            session.recordBaselineKubbsHit(baselineKubbsHit)
        }
        
        // Handle king hit
        if kingHit {
            session.kingHit = true // Mark that the king was hit - game ends!
        }
        
        // Update both round and session state at once
        currentRound = round
        currentSession = session
        
        // Check if game is over (king hit) or round is complete
        if kingHit {
            // King hit - save the current round first, then end the game
            print("📱 King hit - saving final round and ending session")
            round.completeRound()
            session.addRound(round)
            currentSession = session
            currentRound = nil
            
            endSession()
        } else {
            let roundComplete = isRoundComplete(round)
            print("📱 isRoundComplete check: \(roundComplete), round=\(round.roundNumber), blast=\(round.blastData.batonsUsed), 8m=\(round.eightMeterData.batonsUsed)")
            if roundComplete {
                // Round complete but king not hit - continue to next round
                completeCurrentRound()
            }
        }
    }
    
    func addBlastBatonThrowWithKubbs(isHit: Bool, newlyKnockedDownKubbs: Set<Int>) {
        guard var round = currentRound else { return }
        
        // Update the knocked down kubbs set
        if isHit {
            knockedDownKubbs.formUnion(newlyKnockedDownKubbs)
        }
        
        // Add the baton throw with the count of newly knocked down kubbs
        round.blastData.addBatonThrow(isHit: isHit, kubbsHit: newlyKnockedDownKubbs.count)
        currentRound = round
        
        // Check if blast phase is complete
        if round.blastData.isComplete {
            completeCurrentRound()
        }
        
        updateSessionStats()
    }
    
    // MARK: - Round Completion Helper Functions
    
    private func getBatonLimitForRound(_ roundNumber: Int) -> Int {
        switch roundNumber {
        case 1:
            return 2
        case 2:
            return 4
        default:
            return 6
        }
    }
    
    private func isEightMeterPhaseComplete(_ round: FullGameSimRoundStruct) -> Bool {
        let batonLimit = getBatonLimitForRound(round.roundNumber)
        return round.eightMeterData.batonsUsed >= batonLimit
    }
    
    private func isRoundComplete(_ round: FullGameSimRoundStruct) -> Bool {
        // For Round 1, check if 8-meter phase is complete (all batons used)
        if round.roundNumber == 1 {
            return isEightMeterPhaseComplete(round)
        }
        
        // For other rounds, check if attacking phase is complete
        return isAttackingPhaseComplete(round)
    }
    
    private func isAttackingPhaseComplete(_ round: FullGameSimRoundStruct) -> Bool {
        let batonLimit = getBatonLimitForRound(round.roundNumber)
        let totalBatonsUsed = round.blastData.batonsUsed + round.eightMeterData.batonsUsed
        return totalBatonsUsed >= batonLimit
    }
    
    func completeCurrentRound() {
        guard var session = currentSession,
              var round = currentRound else { return }
        
        // Check for uncleared field kubbs (only for rounds 2+)
        if round.roundNumber > 1 {
            let totalFieldKubbs = round.inkastData.totalFieldKubbsForAttacking
            let clearedFieldKubbs = round.blastData.kubbsClearedFirstThrow
            let unclearedKubbs = totalFieldKubbs - clearedFieldKubbs
            
            if unclearedKubbs > 0 {
                // Team left field kubbs uncleared
                round.unclearedFieldKubbs = unclearedKubbs
                
                // Store uncleared kubbs for the current attacking team (they'll need to clear these in 2 rounds)
                if session.currentAttackingTeam == 1 {
                    session.team1UnclearedKubbs = unclearedKubbs
                } else {
                    session.team2UnclearedKubbs = unclearedKubbs
                }
                
                print("📱 Round \(round.roundNumber): Team \(session.currentAttackingTeam) left \(unclearedKubbs) field kubbs uncleared")
                print("📱 Opponent (Team \(session.currentAttackingTeam == 1 ? 2 : 1)) will have A-Line advantage in next round")
            } else {
                // All field kubbs cleared - no A-Line for opponent
                if session.currentAttackingTeam == 1 {
                    session.team1UnclearedKubbs = 0
                } else {
                    session.team2UnclearedKubbs = 0
                }
                print("📱 Round \(round.roundNumber): Team \(session.currentAttackingTeam) cleared all field kubbs - no A-Line for opponent")
            }
        }
        
        round.completeRound()
        session.addRound(round)
        
        print("📱 Completing round \(currentRoundNumber)")
        
        // Move to next round
        currentRoundNumber += 1
        session.currentRound = currentRoundNumber // Update session's currentRound to match
        
        currentSession = session
        
        // Automatically start next round
        generateNewRound()
        
        // Save session
        saveSession()
        updateSessionStats()
    }
    
    func startNextRound() {
        generateNewRound()
    }
    
    // MARK: - Data Persistence
    
    private func saveSession() {
        guard let session = currentSession else { 
            print("⚠️ saveSession called but no current session")
            return 
        }
        
        print("💾 Saving session: \(session.id)")
        print("   - isComplete: \(session.isComplete)")
        print("   - isPaused: \(session.isPaused)")
        print("   - currentRound: \(session.currentRound)")
        
        // Save to Core Data
        let context = persistenceController.container.viewContext
        
        // Check if session already exists
        let fetchRequest: NSFetchRequest<FullGameSimSession> = FullGameSimSession.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", session.id)
        
        do {
            let existingSessions = try context.fetch(fetchRequest)
            let coreDataSession: FullGameSimSession
            
            if let existing = existingSessions.first {
                // Update existing session
                coreDataSession = existing
                coreDataSession.date = session.date
                coreDataSession.startTime = session.startTime
                coreDataSession.endTime = session.endTime
                coreDataSession.isComplete = session.isComplete
                coreDataSession.isPaused = session.isPaused
                coreDataSession.currentRound = Int16(session.currentRound)
                coreDataSession.currentPhase = session.currentPhase.rawValue
                coreDataSession.totalRounds = Int16(session.totalRounds)
                coreDataSession.totalInkastKubbs = Int16(session.totalInkastKubbs)
                coreDataSession.totalKubbsClearedFirstThrow = Int16(session.totalKubbsClearedFirstThrow)
                coreDataSession.totalBatonsUsed = Int16(session.totalBatonsUsed)
                coreDataSession.totalPenaltyKubbs = Int16(session.totalPenaltyKubbs)
                coreDataSession.totalNeighborKubbs = Int16(session.totalNeighborKubbs)
                coreDataSession.totalMisses = Int16(session.totalMisses)
                coreDataSession.totalEightMeterHits = Int16(session.totalEightMeterHits)
                coreDataSession.totalEightMeterBatons = Int16(session.totalEightMeterBatons)
                
                // TODO: Core Data integration temporarily disabled - using CloudKit only
                // coreDataSession.team1BaselineKubbs = Int16(session.team1BaselineKubbs)
                // coreDataSession.team2BaselineKubbs = Int16(session.team2BaselineKubbs)
                coreDataSession.modifiedAt = session.modifiedAt
            } else {
                // Create new session
                coreDataSession = FullGameSimSession(context: context)
                coreDataSession.id = session.id
                coreDataSession.date = session.date
                coreDataSession.startTime = session.startTime
                coreDataSession.endTime = session.endTime
                coreDataSession.isComplete = session.isComplete
                coreDataSession.isPaused = session.isPaused
                coreDataSession.currentRound = Int16(session.currentRound)
                coreDataSession.currentPhase = session.currentPhase.rawValue
                coreDataSession.totalRounds = Int16(session.totalRounds)
                coreDataSession.totalInkastKubbs = Int16(session.totalInkastKubbs)
                coreDataSession.totalKubbsClearedFirstThrow = Int16(session.totalKubbsClearedFirstThrow)
                coreDataSession.totalBatonsUsed = Int16(session.totalBatonsUsed)
                coreDataSession.totalPenaltyKubbs = Int16(session.totalPenaltyKubbs)
                coreDataSession.totalNeighborKubbs = Int16(session.totalNeighborKubbs)
                coreDataSession.totalMisses = Int16(session.totalMisses)
                coreDataSession.totalEightMeterHits = Int16(session.totalEightMeterHits)
                coreDataSession.totalEightMeterBatons = Int16(session.totalEightMeterBatons)

                // TODO: Core Data integration temporarily disabled - using CloudKit only
                // coreDataSession.team1BaselineKubbs = Int16(session.team1BaselineKubbs)
                // coreDataSession.team2BaselineKubbs = Int16(session.team2BaselineKubbs)
                coreDataSession.createdAt = session.createdAt
                coreDataSession.modifiedAt = session.modifiedAt
            }
            
            try context.save()
            print("✅ Saved to Core Data")
            
            // Save to local storage (UserDefaults) for resume functionality
            LocalStorageManager.shared.saveFullGameSimSession(session)
            print("✅ Saved to local storage (UserDefaults)")
            
            // Sync to CloudKit
            Task {
                await cloudKitManager.saveFullGameSimSession(session)
                print("✅ Synced to CloudKit")
            }
            
        } catch {
            print("❌ Error saving FullGameSimSession: \(error)")
        }
    }
    
    @MainActor
    func loadIncompleteSession() async {
        print("🔄 Loading incomplete sessions from local storage...")
        
        // Load from local storage
        let allSessions = LocalStorageManager.shared.loadFullGameSimSessions()
        print("🔄 Found \(allSessions.count) total Full Game Sim sessions in local storage")
        
        // Debug: Print all sessions
        for (index, session) in allSessions.enumerated() {
            print("   Session \(index + 1): id=\(session.id), isComplete=\(session.isComplete), isPaused=\(session.isPaused), round=\(session.currentRound)")
        }
        
        // Find incomplete/paused session
        if let incompleteSession = allSessions.first(where: { !$0.isComplete }) {
            currentSession = incompleteSession
            currentRoundNumber = incompleteSession.currentRound
            currentPhase = incompleteSession.currentPhase
            isSessionActive = false // Don't auto-start, wait for user to choose
            isPaused = true
            
            // Don't setup watch connectivity yet - wait until user actually resumes
            // setupWatchConnectivity() will be called in resumeSession()
            
            updateSessionStats()
            print("✅ Loaded incomplete Full Game Sim session from local storage: \(incompleteSession.id)")
            print("   - Round: \(incompleteSession.currentRound)")
            print("   - Team attacking: \(incompleteSession.currentAttackingTeam)")
            print("   - isPaused: \(incompleteSession.isPaused)")
            print("   - isComplete: \(incompleteSession.isComplete)")
        } else {
            print("❌ No incomplete sessions found")
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
        sessionStats.totalEightMeterHits = session.totalEightMeterHits
        sessionStats.totalEightMeterBatons = session.totalEightMeterBatons
        sessionStats.averageKubbsPerRound = session.averageKubbsPerRound
        sessionStats.averageBatonsPerRound = session.averageBatonsPerRound
        sessionStats.averageKubbsPerBaton = session.averageKubbsPerBaton
        sessionStats.penaltyRate = session.penaltyRate
        sessionStats.neighborRate = session.neighborRate
        sessionStats.eightMeterAccuracy = session.eightMeterAccuracy
    }
}
