//
//  BaseballKubbSessionManager+WatchConnectivity.swift
//  Kubb Manager
//
//  Created by AI Assistant on 10/8/25.
//

import Foundation

// MARK: - Watch Connectivity Extension for BaseballKubbSessionManager

extension BaseballKubbSessionManager: WatchCommunicationDelegate {
    
    /// Sets up watch connectivity for this session manager
    func setupWatchConnectivity() {
        let watchManager = WatchConnectivityManager.shared
        watchManager.delegate = self
    }
    
    /// Notifies watch when session starts
    func notifyWatchSessionStarted() {
        guard currentSession != nil else { return }
        WatchConnectivityManager.shared.notifySessionStarted(sessionType: "Baseball Kubb")
    }
    
    /// Notifies watch when session ends
    func notifyWatchSessionEnded() {
        WatchConnectivityManager.shared.notifySessionEnded()
    }
    
    /// Requests baton throw input from watch
    func requestWatchBatonInput() {
        guard let session = currentSession else { return }
        
        // Don't request input if half inning is over or game is over
        guard !session.isHalfInningOver && !session.gameOver else { return }
        
        let batonNumber = session.currentBaton
        let batonLimit = session.batonLimit
        
        // Determine what the user is throwing at
        var promptText = "Baton \(batonNumber)"
        if session.fieldKubbs > 0 {
            promptText += "\nField Kubbs"
        } else if session.currentBaselineKubbs > 0 {
            promptText += "\nBaseline Kubbs"
        } else {
            promptText += "\nKing Available"
        }
        
        // A single baton can hit field kubbs AND baseline kubbs
        // So maxKubbs should be field kubbs + baseline kubbs
        let maxKubbs = session.fieldKubbs + session.currentBaselineKubbs
        
        let context = BatonThrowContext(
            promptText: promptText,
            allowKubbCount: true,
            maxKubbs: maxKubbs > 0 ? maxKubbs : 1,  // At least 1 for king
            batonNumber: batonNumber,
            totalBatons: batonLimit == 999 ? nil : batonLimit
        )
        
        WatchConnectivityManager.shared.requestBatonThrowInput(context: context)
    }
    
    /// Sends current session state to watch
    func sendSessionStateToWatch() {
        guard let session = currentSession else { return }
        
        let phaseText: String
        if session.gameOver {
            phaseText = "Game Over"
        } else if session.isHalfInningOver {
            phaseText = "Half Inning Complete"
        } else {
            phaseText = "Inning \(session.currentInning) - \(session.isTop ? "Top" : "Bottom")"
        }
        
        let state = WatchSessionState(
            sessionType: "Baseball Kubb",
            isActive: !session.gameOver,
            currentRound: session.currentInning,
            totalRounds: 9,
            currentPhase: phaseText,
            isWatchMode: WatchConnectivityManager.shared.isWatchMode
        )
        
        WatchConnectivityManager.shared.sendSessionState(state)
    }
    
    // MARK: - WatchCommunicationDelegate
    
    nonisolated func didReceiveBatonThrowResult(_ result: BatonThrowResult) {
        print("📱 BaseballKubbSessionManager received baton throw from watch: \(result.isHit), kubbs: \(result.kubbsHit)")
        
        Task { @MainActor in
            guard let session = currentSession else { return }
        
        // Don't process if half inning is over or game is over
        guard !session.isHalfInningOver && !session.gameOver else {
            print("⚠️ Received baton throw but half inning is over or game is over")
            return
        }
        
        if result.isHit {
            // Determine what was hit based on game state
            let fieldKubbsHit: Int
            let baselineKubbsHit: Int
            let kingHit: Bool
            
            if session.fieldKubbs > 0 {
                // Hit field kubbs - but might also hit baseline kubbs if hit more than field kubbs remaining
                if result.kubbsHit > session.fieldKubbs {
                    // Hit all field kubbs plus some baseline kubbs
                    fieldKubbsHit = session.fieldKubbs
                    baselineKubbsHit = min(result.kubbsHit - session.fieldKubbs, session.currentBaselineKubbs)
                    kingHit = false
                } else {
                    // Only hit field kubbs
                    fieldKubbsHit = result.kubbsHit
                    baselineKubbsHit = 0
                    kingHit = false
                }
            } else if session.currentBaselineKubbs > 0 {
                // Hit baseline kubbs
                fieldKubbsHit = 0
                baselineKubbsHit = min(result.kubbsHit, session.currentBaselineKubbs)
                kingHit = false
            } else {
                // Hit king (only if all kubbs are cleared)
                fieldKubbsHit = 0
                baselineKubbsHit = 0
                kingHit = result.kubbsHit > 0
            }
            
            recordHit(fieldKubbsHit: fieldKubbsHit, baselineKubbsHit: baselineKubbsHit, kingHit: kingHit)
            checkGameEnd()
        } else {
            // Miss
            recordMiss()
        }
        
            // Check if game ended
            guard let updatedSession = currentSession else {
                print("📱 Session ended - no more input needed")
                notifyWatchSessionEnded()
                return
            }
            
            // Update watch with new state immediately
            sendSessionStateToWatch()
            
            print("📱 Baseball Kubb - Half inning over: \(updatedSession.isHalfInningOver), Game over: \(updatedSession.gameOver)")
            
            if updatedSession.gameOver {
                print("📱 Game over - ending session")
                notifyWatchSessionEnded()
            } else if updatedSession.isHalfInningOver {
                // Half inning complete - send state to watch and wait for next round request
                print("📱 Half inning complete")
                sendSessionStateToWatch()
                print("📱 Sent Half Inning Complete state to watch - waiting for next round request")
            } else {
                // Request next input if game is still active
                print("📱 Requesting next baton input...")
                requestWatchBatonInput()
            }
        }
    }
    
    nonisolated func didReceiveInkastResult(_ result: InkastResult) {
        // Baseball Kubb doesn't use inkast inputs
        print("⚠️ BaseballKubbSessionManager received unexpected inkast result")
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
        // Baseball Kubb doesn't have phases, just innings
        print("📱 Watch requested next phase - not applicable for Baseball Kubb")
    }
    
    nonisolated func didRequestNextRound() {
        Task { @MainActor in
            // For Baseball Kubb, advance to next half inning
            guard let session = currentSession else { return }
            
            if session.isHalfInningOver && !session.gameOver {
                // Move to next half inning
                self.nextHalf()
                sendSessionStateToWatch()
                // Request the first baton throw for the new half inning
                requestWatchBatonInput()
                print("📱 Watch requested next round - advanced to next half inning")
            } else if session.gameOver {
                // Game is over, can't advance
                print("📱 Watch requested next round but game is over")
            } else {
                // Current half inning not over yet
                print("📱 Watch requested next round but current half inning not complete")
            }
        }
    }
    
    nonisolated func didRequestEndSession() {
        Task { @MainActor in
            // End the current game
            currentSession = nil
            notifyWatchSessionEnded()
            print("📱 Watch requested to end session")
        }
    }
}
