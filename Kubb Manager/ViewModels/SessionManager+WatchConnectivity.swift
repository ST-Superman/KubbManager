//
//  SessionManager+WatchConnectivity.swift
//  Kubb Manager
//
//  Created by AI Assistant on 10/8/25.
//

import Foundation

// MARK: - Watch Connectivity Extension for SessionManager (8-Meter Training)

extension SessionManager: WatchCommunicationDelegate {
    
    /// Sets up watch connectivity for this session manager
    func setupWatchConnectivity() {
        let watchManager = WatchConnectivityManager.shared
        watchManager.delegate = self
    }
    
    /// Notifies watch when session starts
    func notifyWatchSessionStarted() {
        guard isSessionActive else { return }
        WatchConnectivityManager.shared.notifySessionStarted(sessionType: "8M Training")
    }
    
    /// Notifies watch when session ends
    func notifyWatchSessionEnded() {
        WatchConnectivityManager.shared.notifySessionEnded()
    }
    
    /// Requests baton throw input from watch
    func requestWatchBatonInput() {
        guard let session = currentSession,
              let currentRound = session.currentRound else { return }
        
        let throwNumber = currentRound.totalBatonThrows + 1
        let context = BatonThrowContext(
            promptText: "Baton \(throwNumber) of 6",
            allowKubbCount: false,  // 8-meter training is simple hit/miss
            maxKubbs: 1,
            batonNumber: throwNumber,
            totalBatons: 6
        )
        
        WatchConnectivityManager.shared.requestBatonThrowInput(context: context)
    }
    
    /// Sends current session state to watch
    func sendSessionStateToWatch() {
        guard let session = currentSession else { return }
        
        // Determine phase based on round completion status
        let phaseText: String
        if let lastRound = session.rounds.last, lastRound.isComplete, session.currentRound == nil {
            phaseText = "Round Complete"
        } else {
            phaseText = "Throwing"
        }
        
        let state = WatchSessionState(
            sessionType: "8M Training",
            isActive: isSessionActive,
            currentRound: session.rounds.count,
            totalRounds: nil,  // 8-meter doesn't have a fixed round count
            currentPhase: phaseText,
            isWatchMode: WatchConnectivityManager.shared.isWatchMode,
            targetBatons: session.target,
            currentBatons: session.totalBatons,
            isTargetReached: session.isTargetReached
        )
        
        WatchConnectivityManager.shared.sendSessionState(state)
    }
    
    // MARK: - WatchCommunicationDelegate
    
    nonisolated func didReceiveBatonThrowResult(_ result: BatonThrowResult) {
        print("📱 SessionManager received baton throw from watch: \(result.isHit)")
        
        // Record the baton throw
        Task { @MainActor in
            await addBatonResult(isHit: result.isHit)
            
            // Update watch with new state immediately
            sendSessionStateToWatch()
            
            // Check if round is complete
            // After adding the 6th baton, currentRound becomes nil (no incomplete rounds)
            // So we need to check the last round in the rounds array
            if let session = currentSession {
                if let lastRound = session.rounds.last, lastRound.isComplete {
                    // Round was just completed
                    print("📱 8M Training - Round complete: batons: \(lastRound.totalBatonThrows)/6")
                    print("📱 Round complete - sent Round Complete state to watch, waiting for user to start next round")
                } else if let currentRound = session.currentRound {
                    // Round still in progress, request next baton
                    print("📱 8M Training - Round in progress: batons: \(currentRound.totalBatonThrows)/6")
                    print("📱 Requesting next baton input...")
                    requestWatchBatonInput()
                }
            }
        }
    }
    
    nonisolated func didReceiveInkastResult(_ result: InkastResult) {
        // 8-meter training doesn't use inkast inputs
        print("⚠️ SessionManager received unexpected inkast result")
    }
    
    nonisolated func didRequestSessionState() {
        Task { @MainActor in
            sendSessionStateToWatch()
        }
    }
    
    nonisolated func watchConnectivityDidChange(isReachable: Bool) {
        print("⌚️ Watch reachability changed: \(isReachable)")
        // Could update UI to show watch connection status
    }
    
    // MARK: - Watch Mode Support
    
    nonisolated func didRequestNextPhase() {
        // 8M Training doesn't have phases, just rounds
        print("📱 Watch requested next phase - not applicable for 8M Training")
    }
    
    nonisolated func didRequestNextRound() {
        Task { @MainActor in
            // For 8-meter training, check if last round is complete and start next round
            // After a round completes, currentRound becomes nil, so check the last round
            if let session = currentSession,
               let lastRound = session.rounds.last,
               lastRound.isComplete {
                
                // Start new round
                await startNextRound()
                sendSessionStateToWatch()
                // Request the first baton throw for the new round
                requestWatchBatonInput()
                print("📱 Watch requested next round - started new 8M training round")
            } else {
                print("📱 Watch requested next round but last round not found or not complete")
            }
        }
    }
    
    nonisolated func didRequestEndSession() {
        // Complete and end the current session
        Task { @MainActor in
            await completeSession()
            notifyWatchSessionEnded()
            print("📱 Watch requested to end session - session completed and saved")
        }
    }
}
