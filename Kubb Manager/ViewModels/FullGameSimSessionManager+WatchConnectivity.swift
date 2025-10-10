//
//  FullGameSimSessionManager+WatchConnectivity.swift
//  Kubb Manager
//
//  Created by AI Assistant on 10/8/25.
//

import Foundation

// MARK: - Watch Connectivity Extension for FullGameSimSessionManager

extension FullGameSimSessionManager: WatchCommunicationDelegate {
    
    /// Sets up watch connectivity for this session manager
    func setupWatchConnectivity() {
        let watchManager = WatchConnectivityManager.shared
        watchManager.delegate = self
        print("📱 FullGameSimSessionManager.setupWatchConnectivity() called")
    }
    
    /// Notifies watch when session starts
    func notifyWatchSessionStarted() {
        guard currentSession != nil else { return }
        
        // Set this session manager as the delegate to receive watch messages
        WatchConnectivityManager.shared.delegate = self
        print("📱 FullGameSimSessionManager set as watch delegate")
        
        WatchConnectivityManager.shared.notifySessionStarted(sessionType: "Full Game Sim")
    }
    
    /// Notifies watch when session ends
    func notifyWatchSessionEnded() {
        WatchConnectivityManager.shared.notifySessionEnded()
    }
    
    /// Requests appropriate input from watch based on current game phase
    func requestWatchInput() {
        guard let round = currentRound else { return }
        
        switch currentPhase {
        case .inkast:
            requestInkastInput()
        case .attacking:
            requestAttackingInput(round: round)
        case .roundComplete:
            // Round is complete, no input needed
            break
        }
    }
    
    /// Requests inkast input from watch
    private func requestInkastInput() {
        // Determine which inkast input to request based on state
        if currentRound?.inkastData.kubbsOutFirstAttempt == 0 && currentRound?.inkastData.kubbsOutSecondAttempt == 0 {
            // First attempt
            requestInkastFirstAttemptInput()
        } else if let firstOut = currentRound?.inkastData.kubbsOutFirstAttempt, firstOut > 0,
                  currentRound?.inkastData.kubbsOutSecondAttempt == 0 {
            // Second attempt needed
            requestInkastSecondAttemptInput()
        } else {
            // Neighbor check
            requestInkastNeighborInput()
        }
    }
    
    private func requestInkastFirstAttemptInput() {
        guard let round = currentRound else { return }
        
        let context = InkastContext(
            promptText: "Out of bounds\n(1st attempt)?",
            maxCount: round.inkastData.inkastKubbs,
            inkastType: .firstAttemptOut
        )
        
        WatchConnectivityManager.shared.requestInkastInput(context: context)
    }
    
    private func requestInkastSecondAttemptInput() {
        guard let round = currentRound else { return }
        
        let context = InkastContext(
            promptText: "Out of bounds\n(2nd attempt)?",
            maxCount: round.inkastData.kubbsOutFirstAttempt,
            inkastType: .secondAttemptOut
        )
        
        WatchConnectivityManager.shared.requestInkastInput(context: context)
    }
    
    private func requestInkastNeighborInput() {
        guard let round = currentRound else { return }
        
        let kubbsInBounds = round.inkastData.inkastKubbs - round.inkastData.penaltyKubbs
        let context = InkastContext(
            promptText: "How many\nneighbors?",
            maxCount: kubbsInBounds,
            inkastType: .neighbors
        )
        
        WatchConnectivityManager.shared.requestInkastInput(context: context)
    }
    
    /// Requests attacking phase input from watch
    private func requestAttackingInput(round: FullGameSimRoundStruct) {
        guard let session = currentSession else { return }
        
        let hasFieldKubbs = round.inkastData.totalFieldKubbsForAttacking > knockedDownKubbs.count
        let hasALine = round.hasALine
        let currentTeam = session.currentAttackingTeam
        
        // Calculate total batons used in this round (blast + 8-meter)
        let totalBatonsUsed = round.blastData.batonsUsed + round.eightMeterData.batonsUsed
        let throwNumber = totalBatonsUsed + 1
        
        let promptText: String
        let maxKubbs: Int
        
        if hasFieldKubbs {
            // Blasting phase - field kubbs still remain
            let remainingFieldKubbs = round.inkastData.totalFieldKubbsForAttacking - knockedDownKubbs.count
            
            // A single baton can hit field kubbs AND baseline kubbs
            // So maxKubbs should be field kubbs + baseline kubbs
            let baselineKubbs = session.currentBaselineKubbs
            maxKubbs = remainingFieldKubbs + baselineKubbs
            
            let locationText = hasALine ? "⚡ A-Line" : "📏 Baseline"
            promptText = "Team \(currentTeam) - Baton \(throwNumber)\nField Kubbs (\(locationText))"
        } else {
            // 8-meter phase - all field kubbs cleared
            let baselineKubbs = session.currentBaselineKubbs
            
            if baselineKubbs == 0 {
                // King shot only - ALL field kubbs AND baseline kubbs are cleared
                promptText = "Team \(currentTeam) - Baton \(throwNumber)\n👑 King Shot"
                maxKubbs = 1 // Only the king remains
            } else {
                // Baseline kubbs still remain (field kubbs are cleared)
                let locationText = hasALine ? "⚡ A-Line" : "📏 Baseline"
                promptText = "Team \(currentTeam) - Baton \(throwNumber)\nBaseline (\(locationText))"
                maxKubbs = baselineKubbs
            }
        }
        
        let context = BatonThrowContext(
            promptText: promptText,
            allowKubbCount: true,
            maxKubbs: maxKubbs,
            batonNumber: throwNumber,
            totalBatons: getBatonLimitForRound(round.roundNumber)
        )
        
        WatchConnectivityManager.shared.requestBatonThrowInput(context: context)
    }
    
    /// Sends current session state to watch
    func sendSessionStateToWatch() {
        guard let session = currentSession, let round = currentRound else { return }
        
        let phaseText: String
        switch currentPhase {
        case .inkast:
            phaseText = "Inkast"
        case .attacking:
            let hasFieldKubbs = round.inkastData.totalFieldKubbsForAttacking > knockedDownKubbs.count
            phaseText = hasFieldKubbs ? "Blasting" : "8-Meter"
        case .roundComplete:
            phaseText = "Round Complete"
        }
        
        let state = WatchSessionState(
            sessionType: "Full Game Sim",
            isActive: !session.isComplete,
            currentRound: round.roundNumber,
            totalRounds: 3,
            currentPhase: phaseText,
            isWatchMode: WatchConnectivityManager.shared.isWatchMode,
            hasALine: round.hasALine,
            currentAttackingTeam: session.currentAttackingTeam
        )
        
        WatchConnectivityManager.shared.sendSessionState(state)
    }
    
    // MARK: - WatchCommunicationDelegate
    
    nonisolated func didReceiveBatonThrowResult(_ result: BatonThrowResult) {
        print("📱 FullGameSimSessionManager received baton throw from watch: \(result.isHit), kubbs: \(result.kubbsHit)")
        
        Task { @MainActor in
            guard let round = currentRound else { return }
            
            // Only process if in attacking phase
            guard currentPhase == .attacking else {
            print("⚠️ Received baton throw but not in attacking phase")
            return
        }
        
        let totalFieldKubbs = round.inkastData.totalFieldKubbsForAttacking
        let clearedFieldKubbs = knockedDownKubbs.count
        let remainingFieldKubbs = totalFieldKubbs - clearedFieldKubbs
        let hasFieldKubbs = remainingFieldKubbs > 0
        
        print("📱 Processing baton throw - Field kubbs: total=\(totalFieldKubbs), cleared=\(clearedFieldKubbs), remaining=\(remainingFieldKubbs)")
        
        if hasFieldKubbs {
            // Blasting phase - but baton might hit field kubbs AND baseline kubbs
            if result.isHit && result.kubbsHit > remainingFieldKubbs {
                // Hit more kubbs than field kubbs remaining - some must be baseline kubbs
                let fieldKubbsHit = remainingFieldKubbs
                let baselineKubbsHit = result.kubbsHit - remainingFieldKubbs
                
                print("📱 Baton hit both field kubbs (\(fieldKubbsHit)) and baseline kubbs (\(baselineKubbsHit))")
                
                addBlastBatonThrowWithFieldAndBaseline(
                    fieldKubbsHit: fieldKubbsHit,
                    baselineKubbsHit: baselineKubbsHit,
                    kingHit: false
                )
            } else {
                // Only hit field kubbs (or missed)
                addBlastBatonThrow(isHit: result.isHit, kubbsHit: result.kubbsHit)
            }
        } else {
            // 8-meter phase
            if result.isHit {
                // Determine if baseline kubbs or king was hit
                if let session = currentSession, session.currentBaselineKubbs > 0 {
                    // Hit baseline kubbs
                    addBlastBatonThrowWithFieldAndBaseline(
                        fieldKubbsHit: 0,
                        baselineKubbsHit: result.kubbsHit,
                        kingHit: false
                    )
                } else {
                    // Hit king
                    addBlastBatonThrowWithFieldAndBaseline(
                        fieldKubbsHit: 0,
                        baselineKubbsHit: 0,
                        kingHit: true
                    )
                }
            } else {
                // Miss
                addEightMeterBatonThrow(isHit: false)
            }
            }
            
            // Check if session was ended (e.g., king hit)
            guard isSessionActive, let round = currentRound else {
                print("📱 Session ended - no more input needed")
                notifyWatchSessionEnded()
                return
            }
            
            // Update watch with new state immediately
            sendSessionStateToWatch()
            
            // Check if round is complete or request next input
            print("📱 Current phase after baton throw: \(currentPhase)")
            print("📱 Round batons used: blast=\(round.blastData.batonsUsed), 8m=\(round.eightMeterData.batonsUsed)")
            
            if currentPhase == .roundComplete {
                // Round complete - send state to watch and wait for next round request
                print("📱 Round complete")
                if currentRoundNumber >= 3 {
                    print("📱 All rounds complete - session ending")
                    notifyWatchSessionEnded()
                } else {
                    sendSessionStateToWatch()
                    print("📱 Sent Round Complete state to watch - waiting for next round request")
                }
            } else if currentPhase == .attacking {
                print("📱 Requesting next attacking input...")
                requestAttackingInput(round: round)
            } else if currentPhase == .inkast {
                print("📱 New round started with inkast phase - requesting inkast input...")
                requestInkastInput()
            } else {
                print("⚠️ Unexpected phase: \(currentPhase)")
            }
        }
    }
    
    nonisolated func didReceiveInkastResult(_ result: InkastResult) {
        print("📱 FullGameSimSessionManager received inkast result: \(result.inkastType), count: \(result.count)")
        
        Task { @MainActor in
            guard var round = currentRound else { return }
        
        switch result.inkastType {
        case .firstAttemptOut:
            round.inkastData.kubbsOutFirstAttempt = result.count
            currentRound = round
            
            // Automatically request next input
            if result.count > 0 {
                requestInkastSecondAttemptInput()
            } else {
                requestInkastNeighborInput()
            }
            
        case .secondAttemptOut:
            round.inkastData.kubbsOutSecondAttempt = result.count
            round.inkastData.penaltyKubbs = result.count
            currentRound = round
            
            // Automatically request neighbor input
            requestInkastNeighborInput()
            
        case .neighbors:
            round.inkastData.neighborKubbs = result.count
            currentRound = round
            
            // Complete inkast phase
            completeInkastPhase()
            
            // Request first attacking input
            if let updatedRound = currentRound {
                requestAttackingInput(round: updatedRound)
            }
        }
            
            // Update watch with new state
            sendSessionStateToWatch()
        }
    }
    
    nonisolated func didRequestSessionState() {
        Task { @MainActor in
            sendSessionStateToWatch()
        }
    }
    
    nonisolated func watchConnectivityDidChange(isReachable: Bool) {
        print("⌚️ Watch reachability changed: \(isReachable)")
    }
    
    // MARK: - Watch Mode Support
    
    nonisolated func didRequestNextPhase() {
        Task { @MainActor in
            // Advance to next phase in Full Game Sim
            switch currentPhase {
            case .inkast:
                // Complete inkast phase and move to attacking
                completeInkastPhase()
            case .attacking:
                // Move to round complete phase
                currentPhase = .roundComplete
            case .roundComplete:
                // Move to next round or complete game
                if currentRoundNumber >= 3 {
                    // Game complete
                    currentSession = nil
                    isSessionActive = false
                    notifyWatchSessionEnded()
                } else {
                    // Start next round
                    currentRoundNumber += 1
                    currentPhase = .inkast
                    generateNewRound()
                }
            }
            print("📱 Watch requested next phase - advanced from \(currentPhase)")
        }
    }
    
    nonisolated func didRequestNextRound() {
        Task { @MainActor in
            if currentPhase == .roundComplete && currentRoundNumber < 3 {
                // Start next round
                currentRoundNumber += 1
                currentPhase = .inkast
                generateNewRound()
                sendSessionStateToWatch()
                // Request the first input for the new round (inkast)
                requestInkastInput()
                print("📱 Watch requested next round - starting round \(currentRoundNumber)")
            } else {
                print("📱 Watch requested next round but not applicable at current phase/round")
            }
        }
    }
    
    nonisolated func didRequestEndSession() {
        Task { @MainActor in
            // End the current game
            currentSession = nil
            isSessionActive = false
            notifyWatchSessionEnded()
            print("📱 Watch requested to end session")
        }
    }
    
    // MARK: - Helper Methods
    
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
}
