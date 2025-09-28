//
//  BaseballKubbSessionManager.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 9/23/25.
//

import Foundation
import Combine

@MainActor
class BaseballKubbSessionManager: ObservableObject {
    @Published var currentSession: BaseballKubbSession?
    @Published var lastSession: BaseballKubbSession?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let cloudKitManager = CloudKitManager.shared
    private let localStorage = LocalStorageManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        Task {
            await loadLastSession()
        }
    }
    
    // MARK: - Session Management
    
    func startNewGame(awayTeam: String, homeTeam: String) {
        print("🚀 Starting new Baseball Kubb game: \(awayTeam) vs \(homeTeam)")
        
        let newSession = BaseballKubbSession(awayTeam: awayTeam, homeTeam: homeTeam)
        currentSession = newSession
        
        // Save to local storage immediately
        localStorage.saveBaseballKubbSession(newSession)
        
        // Save to CloudKit
        Task {
            await saveSessionToCloudKit(newSession)
        }
        
        print("✅ New Baseball Kubb game started with ID: \(newSession.id)")
    }
    
    func resumeLastGame() {
        guard let lastSession = lastSession else { return }
        
        print("🔄 Resuming last Baseball Kubb game: \(lastSession.id)")
        currentSession = lastSession
    }
    
    func endGame() {
        guard var session = currentSession else { return }
        
        print("🏁 Ending Baseball Kubb game: \(session.id)")
        
        session.isComplete = true
        currentSession = session
        lastSession = session
        
        // Save to local storage
        localStorage.saveBaseballKubbSession(session)
        
        // Save to CloudKit
        Task {
            await saveSessionToCloudKit(session)
        }
    }
    
    func resetSession() {
        print("🔄 Resetting Baseball Kubb session")
        currentSession = nil
    }
    
    // MARK: - Game Actions
    
    func recordHit(fieldKubbsHit: Int, baselineKubbsHit: Int, kingHit: Bool) {
        guard var session = currentSession else { return }
        
        print("⚾ Recording hit - Field: \(fieldKubbsHit), Baseline: \(baselineKubbsHit), King: \(kingHit)")
        
        session.recordHit(fieldKubbsHit: fieldKubbsHit, baselineKubbsHit: baselineKubbsHit, kingHit: kingHit)
        currentSession = session
        
        // Save to local storage only (CloudKit sync happens at end of half/game)
        localStorage.saveBaseballKubbSession(session)
    }
    
    func recordMiss() {
        guard var session = currentSession else { return }
        
        print("❌ Recording miss")
        
        session.recordMiss()
        currentSession = session
        
        // Save to local storage only (CloudKit sync happens at end of half/game)
        localStorage.saveBaseballKubbSession(session)
    }
    
    func nextHalf() {
        guard var session = currentSession else { return }
        
        print("🔄 Moving to next half")
        
        session.nextHalf()
        currentSession = session
        
        // Check if game should end after transitioning to bottom of 9th
        session.checkGameEnd()
        currentSession = session
        
        // Save to local storage
        localStorage.saveBaseballKubbSession(session)
        
        // Sync to CloudKit at end of half inning
        Task {
            await saveSessionToCloudKit(session)
        }
    }
    
    func endHalfInning() {
        guard var session = currentSession else { return }
        
        print("🏁 Ending half inning")
        
        session.endHalfInning()
        currentSession = session
        
        // Save to local storage
        localStorage.saveBaseballKubbSession(session)
        
        // Sync to CloudKit at end of half inning
        Task {
            await saveSessionToCloudKit(session)
        }
    }
    
    func checkGameEnd() {
        guard var session = currentSession else { return }
        
        session.checkGameEnd()
        currentSession = session
        
        if session.gameOver {
            // Save to local storage
            localStorage.saveBaseballKubbSession(session)
            
            // Save to CloudKit
            Task {
                await saveSessionToCloudKit(session)
            }
        }
    }
    
    func undoLastThrow() {
        guard var session = currentSession else { return }
        
        print("↩️ Undoing last throw")
        
        session.restoreThrowState()
        currentSession = session
        
        // Save to local storage only (CloudKit sync happens at end of half/game)
        localStorage.saveBaseballKubbSession(session)
    }
    
    func resetHalfInning() {
        guard var session = currentSession else { return }
        
        print("🔄 Resetting half inning")
        
        session.resetHalfInning()
        currentSession = session
        
        // Save to local storage only (CloudKit sync happens at end of half/game)
        localStorage.saveBaseballKubbSession(session)
    }
    
    // MARK: - Data Persistence
    
    private func loadLastSession() async {
        isLoading = true
        
        do {
            // Load from local storage first
            if let localSession = localStorage.loadLastBaseballKubbSession() {
                lastSession = localSession
                print("📱 Loaded last session from local storage: \(localSession.id)")
            }
            
            // Try to load from CloudKit
            if let cloudSession = try await cloudKitManager.fetchLastBaseballKubbSession() {
                // If we have both, use the more recent one
                if let localSession = lastSession {
                    if cloudSession.modifiedAt > localSession.modifiedAt {
                        lastSession = cloudSession
                        localStorage.saveBaseballKubbSession(cloudSession)
                        print("☁️ Updated with newer CloudKit session: \(cloudSession.id)")
                    }
                } else {
                    lastSession = cloudSession
                    localStorage.saveBaseballKubbSession(cloudSession)
                    print("☁️ Loaded session from CloudKit: \(cloudSession.id)")
                }
            }
            
            isLoading = false
        } catch {
            print("❌ Failed to load last session: \(error)")
            errorMessage = "Failed to load last session: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    private func saveSessionToCloudKit(_ session: BaseballKubbSession) async {
        do {
            try await cloudKitManager.saveBaseballKubbSession(session)
            print("✅ Saved Baseball Kubb session to CloudKit: \(session.id)")
        } catch {
            print("❌ Failed to save session to CloudKit: \(error)")
            errorMessage = "Failed to sync to iCloud: \(error.localizedDescription)"
        }
    }
}
