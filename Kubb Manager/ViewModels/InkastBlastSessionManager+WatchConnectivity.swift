//
//  InkastBlastSessionManager+WatchConnectivity.swift
//  Kubb Manager
//
//  Created by AI Assistant on 10/8/25.
//

import Foundation

// MARK: - Watch Connectivity Extension for InkastBlastSessionManager

extension InkastBlastSessionManager: WatchCommunicationDelegate {
    
    /// Sets up watch connectivity for this session manager
    func setupWatchConnectivity() {
        let watchManager = WatchConnectivityManager.shared
        watchManager.delegate = self
    }
    
    /// Notifies watch when session starts
    func notifyWatchSessionStarted() {
        guard isSessionActive else { return }
        WatchConnectivityManager.shared.notifySessionStarted(sessionType: "Inkast & Blast")
    }
    
    /// Notifies watch when session ends
    func notifyWatchSessionEnded() {
        WatchConnectivityManager.shared.notifySessionEnded()
    }
    
    /// Requests appropriate input from watch based on current round phase
    func requestWatchInput() {
        switch roundPhase {
        case .inkast:
            requestInkastFirstAttemptInput()
        case .firstAttemptResults:
            // This is handled on phone UI
            break
        case .secondAttempt:
            requestInkastSecondAttemptInput()
        case .secondAttemptResults:
            // This is handled on phone UI
            break
        case .neighborCheck:
            requestInkastNeighborInput()
        case .blasting:
            requestBatonThrowInput()
        case .roundComplete:
            // Round is complete, no input needed
            break
        }
    }
    
    /// Requests first attempt inkast input from watch
    private func requestInkastFirstAttemptInput() {
        let context = InkastContext(
            promptText: "Out of bounds\n(1st attempt)?",
            maxCount: currentInkastKubbs,
            inkastType: .firstAttemptOut
        )
        
        WatchConnectivityManager.shared.requestInkastInput(context: context)
    }
    
    /// Requests second attempt inkast input from watch
    private func requestInkastSecondAttemptInput() {
        let context = InkastContext(
            promptText: "Out of bounds\n(2nd attempt)?",
            maxCount: kubbsOutFirstAttempt,
            inkastType: .secondAttemptOut
        )
        
        WatchConnectivityManager.shared.requestInkastInput(context: context)
    }
    
    /// Requests neighbor count input from watch
    private func requestInkastNeighborInput() {
        let kubbsInBounds = currentInkastKubbs - kubbsOutSecondAttempt
        let context = InkastContext(
            promptText: "How many\nneighbors?",
            maxCount: kubbsInBounds,
            inkastType: .neighbors
        )
        
        WatchConnectivityManager.shared.requestInkastInput(context: context)
    }
    
    /// Requests baton throw input from watch for blasting phase
    private func requestBatonThrowInput() {
        guard let round = currentRound else { return }
        
        let throwNumber = round.batonsUsed + 1
        let totalKubbs = round.inkastKubbs - round.penaltyKubbs
        let remainingKubbs = totalKubbs - knockedDownKubbs.count
        
        let context = BatonThrowContext(
            promptText: "Baton \(throwNumber)",
            allowKubbCount: true,
            maxKubbs: remainingKubbs,
            batonNumber: throwNumber,
            totalBatons: 6
        )
        
        WatchConnectivityManager.shared.requestBatonThrowInput(context: context)
    }
    
    /// Sends current session state to watch
    func sendSessionStateToWatch() {
        guard currentSession != nil else { return }
        
        let phaseText: String
        switch roundPhase {
        case .inkast:
            phaseText = "Inkast"
        case .firstAttemptResults, .secondAttempt, .secondAttemptResults, .neighborCheck:
            phaseText = "Inkast Setup"
        case .blasting:
            phaseText = "Blasting"
        case .roundComplete:
            phaseText = "Round Complete"
        }
        
        let state = WatchSessionState(
            sessionType: "Inkast & Blast",
            isActive: isSessionActive,
            currentRound: currentRoundNumber,
            totalRounds: nil,
            currentPhase: phaseText,
            isWatchMode: WatchConnectivityManager.shared.isWatchMode
        )
        
        WatchConnectivityManager.shared.sendSessionState(state)
    }
    
    // MARK: - WatchCommunicationDelegate
    
    nonisolated func didReceiveBatonThrowResult(_ result: BatonThrowResult) {
        print("📱 InkastBlastSessionManager received baton throw from watch: \(result.isHit), kubbs: \(result.kubbsHit)")
        
        Task { @MainActor in
            // Only process if in blasting phase
            guard roundPhase == .blasting else {
                print("⚠️ Received baton throw but not in blasting phase")
                return
            }
            
            // Record the baton throw
            addBatonThrow(isHit: result.isHit, kubbsHit: result.kubbsHit)
            
            // Update watch with new state immediately
            sendSessionStateToWatch()
            
            // If round is not complete, request next input
            print("📱 Inkast & Blast - Phase after baton throw: \(roundPhase)")
            if roundPhase == .blasting {
                print("📱 Requesting next baton input...")
                requestBatonThrowInput()
            } else if roundPhase == .roundComplete {
                // Round is complete - send state to watch and wait for next round request
                print("📱 Round complete")
                sendSessionStateToWatch()
                print("📱 Sent Round Complete state to watch - waiting for next round request")
            } else {
                print("⚠️ Unexpected phase: \(roundPhase)")
            }
        }
    }
    
    nonisolated func didReceiveInkastResult(_ result: InkastResult) {
        print("📱 InkastBlastSessionManager received inkast result: \(result.inkastType), count: \(result.count)")
        
        Task { @MainActor in
            switch result.inkastType {
        case .firstAttemptOut:
            recordFirstAttemptResults(outOfBounds: result.count)
            
            // Update watch with new state immediately
            sendSessionStateToWatch()
            
            // Automatically request next input
            if result.count > 0 {
                requestInkastSecondAttemptInput()
            } else {
                requestInkastNeighborInput()
            }
            
        case .secondAttemptOut:
            recordSecondAttemptResults(outOfBounds: result.count)
            
            // Update watch with new state immediately
            sendSessionStateToWatch()
            
            // Automatically request neighbor input
            requestInkastNeighborInput()
            
        case .neighbors:
            recordNeighborKubbs(count: result.count)
            
            // Finalize inkast and move to blasting
            finalizeInkast()
            
            // Update watch with new state immediately
            sendSessionStateToWatch()
            
            // Request first baton throw
            requestBatonThrowInput()
            }
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
        // Advance to next phase in the sequence
        switch roundPhase {
        case .inkast:
            // Start first attempt input
            requestInkastFirstAttemptInput()
        case .firstAttemptResults:
            // Move to second attempt or neighbor check
            if kubbsOutFirstAttempt > 0 {
                roundPhase = .secondAttempt
                requestInkastSecondAttemptInput()
            } else {
                roundPhase = .neighborCheck
                requestInkastNeighborInput()
            }
        case .secondAttempt:
            roundPhase = .secondAttemptResults
            requestInkastSecondAttemptInput()
        case .secondAttemptResults:
            roundPhase = .neighborCheck
            requestInkastNeighborInput()
        case .neighborCheck:
            // Move to blasting
            finalizeInkast()
            requestBatonThrowInput()
        case .blasting:
            // Check if round is complete
            if let round = currentRound, round.isComplete {
                completeCurrentRound()
                roundPhase = .roundComplete
            }
        case .roundComplete:
            // Start next round
            startNextRound()
        }
        print("📱 Watch requested next phase - advanced from \(roundPhase)")
        }
    }
    
    nonisolated func didRequestNextRound() {
        Task { @MainActor in
            if roundPhase == .roundComplete {
                startNextRound()
                sendSessionStateToWatch()
                // Request the first input for the new round (inkast)
                requestWatchInput()
                print("📱 Watch requested next round - starting round \(currentRoundNumber)")
            } else {
                print("📱 Watch requested next round but current round not complete")
            }
        }
    }
    
    nonisolated func didRequestEndSession() {
        Task { @MainActor in
            // End the current session
            currentSession = nil
            isSessionActive = false
            notifyWatchSessionEnded()
            print("📱 Watch requested to end session")
        }
    }
    
    // MARK: - Helper Methods
    
    /// Finalizes inkast phase and prepares for blasting
    private func finalizeInkast() {
        guard var round = currentRound else { return }
        
        // Record inkast results
        round.recordInkastResults(
            firstAttemptOut: kubbsOutFirstAttempt,
            secondAttemptOut: kubbsOutSecondAttempt,
            neighbors: neighborKubbs
        )
        
        currentRound = round
        roundPhase = .blasting
    }
}
