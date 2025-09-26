//
//  SessionManager.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 9/23/25.
//

import Foundation
import Combine

@MainActor
class SessionManager: ObservableObject {
    @Published var currentSession: PracticeSession?
    @Published var isSessionActive: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let cloudKitManager = CloudKitManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        Task {
            await loadIncompleteSession()
        }
    }
    
    // MARK: - Session Management
    
    func startNewSession(target: Int) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let newSession = PracticeSession(target: target)
            currentSession = newSession
            isSessionActive = true
            
            try await cloudKitManager.saveSession(newSession)
            isLoading = false
        } catch {
            errorMessage = cloudKitManager.handleCloudKitError(error)
            isLoading = false
        }
    }
    
    func loadIncompleteSession() async {
        isLoading = true
        
        do {
            if let incompleteSession = try await cloudKitManager.fetchIncompleteSession() {
                currentSession = incompleteSession
                isSessionActive = true
            } else {
                currentSession = nil
                isSessionActive = false
            }
            isLoading = false
        } catch {
            errorMessage = cloudKitManager.handleCloudKitError(error)
            isLoading = false
        }
    }
    
    func addBatonResult(isHit: Bool) async {
        guard var session = currentSession else { return }
        
        session.addBatonResult(isHit: isHit)
        currentSession = session
        
        // Save only when round is complete
        if let currentRound = session.currentRound, currentRound.isRoundComplete {
            await saveSession()
        }
        
        // Check if target is reached
        if session.isTargetReached {
            await completeSession()
        }
    }
    
    func completeSession() async {
        guard var session = currentSession else { return }
        
        isLoading = true
        
        session.completeSession()
        currentSession = session
        
        // Save session completion
        await saveSession()
        
        isSessionActive = false
        isLoading = false
    }
    
    func endSessionEarly() async {
        guard var session = currentSession else { return }
        
        isLoading = true
        
        session.endSessionEarly()
        currentSession = session
        
        // Save session state
        await saveSession()
        
        isSessionActive = false
        isLoading = false
    }
    
    func cancelSession() async {
        guard let session = currentSession else { return }
        
        isLoading = true
        
        do {
            try await cloudKitManager.deleteSession(session)
            currentSession = nil
            isSessionActive = false
            isLoading = false
        } catch {
            errorMessage = cloudKitManager.handleCloudKitError(error)
            isLoading = false
        }
    }
    
    func resetCurrentRound() async {
        guard var session = currentSession else { return }
        
        session.resetCurrentRound()
        currentSession = session
        
        // Save round reset
        await saveSession()
    }
    
    // MARK: - Computed Properties
    
    var progressPercentage: Double {
        return currentSession?.progressPercentage ?? 0.0
    }
    
    var totalKubbs: Int {
        return currentSession?.totalKubbs ?? 0
    }
    
    var totalBatons: Int {
        return currentSession?.totalBatons ?? 0
    }
    
    var accuracy: Double {
        return currentSession?.accuracy ?? 0.0
    }
    
    var currentRound: Round? {
        return currentSession?.currentRound
    }
    
    var isTargetReached: Bool {
        return currentSession?.isTargetReached ?? false
    }
    
    var target: Int {
        return currentSession?.target ?? 0
    }
    
    // MARK: - Session Recovery
    
    func shouldShowRecoveryAlert() -> Bool {
        return hasIncompleteSession() && !isSessionActive
    }
    
    func resumeSession() {
        guard currentSession != nil else { return }
        isSessionActive = true
    }
    
    func deleteIncompleteSession() async {
        guard let session = currentSession else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await cloudKitManager.deleteSession(session)
            currentSession = nil
            isSessionActive = false
            isLoading = false
        } catch {
            errorMessage = cloudKitManager.handleCloudKitError(error)
            isLoading = false
        }
    }
    
    func hasIncompleteSession() -> Bool {
        return currentSession?.isIncomplete ?? false
    }
    
    // MARK: - Private Methods
    
    private func saveSession() async {
        guard let session = currentSession else { return }
        
        do {
            try await cloudKitManager.saveSession(session)
        } catch {
            errorMessage = cloudKitManager.handleCloudKitError(error)
        }
    }
    
    // MARK: - App Lifecycle
    
    func handleAppWillResignActive() {
        // Save when app goes to background
        if isSessionActive {
            Task {
                await saveSession()
            }
        }
    }
    
    func handleAppDidEnterBackground() {
        // Save when app enters background
        if isSessionActive {
            Task {
                await saveSession()
            }
        }
    }
    
    deinit {
        // Save on deinit if session is active
        Task { @MainActor [weak self] in
            if self?.isSessionActive == true {
                await self?.saveSession()
            }
        }
    }
}
