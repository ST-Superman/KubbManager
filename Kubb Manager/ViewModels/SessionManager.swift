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
            print("🚀 Starting new practice session with target: \(target)")
            
            // Create new session with enhanced logging
            let newSession = PracticeSession(target: target)
            print("📝 Created session with ID: \(newSession.id)")
            
            // Pre-save duplicate check
            await performPreSaveDuplicateCheck(for: newSession)
            
            currentSession = newSession
            isSessionActive = true
            
            try await cloudKitManager.saveSession(newSession)
            print("✅ Successfully started and saved new session: \(newSession.id)")
            isLoading = false
        } catch {
            print("❌ Failed to start new session: \(error)")
            errorMessage = cloudKitManager.handleCloudKitError(error)
            isLoading = false
        }
    }
    
    private func performPreSaveDuplicateCheck(for session: PracticeSession) async {
        do {
            print("🔍 Performing pre-save duplicate check for session: \(session.id)")
            
            // Check if a session with this ID already exists in CloudKit
            if let existingRecord = try await cloudKitManager.findRecordBySessionId(session.id) {
                print("⚠️ WARNING: Session with ID \(session.id) already exists in CloudKit!")
                print("   - This could indicate a duplicate session creation issue")
                print("   - Existing record created at: \(existingRecord.creationDate ?? Date.distantPast)")
                print("   - New session created at: \(session.createdAt)")
                
                // Log additional details for debugging
                if let existingSessionId = existingRecord["sessionId"] as? String {
                    print("   - Existing sessionId: \(existingSessionId)")
                }
                if let existingDate = existingRecord["date"] as? Date {
                    print("   - Existing date: \(existingDate)")
                }
            } else {
                print("✅ No duplicate found - session ID is unique")
            }
        } catch {
            print("⚠️ Pre-save duplicate check failed: \(error)")
            // Don't fail the session creation, just log the warning
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
        
        // Check if the session is from a different day and should be ended
        if !Calendar.current.isDateInToday(session.date) {
            // Session is from a different day - end it automatically
            await endSessionEarly()
            return
        }
        
        session.addBatonResult(isHit: isHit)
        currentSession = session
        
        // Save only when round is complete
        if let currentRound = session.currentRound, currentRound.isRoundComplete {
            await saveSession()
        }
        
        // Note: Target reached check is now handled in the UI layer
        // The session will only be completed when the user explicitly chooses to end it
    }
    
    func completeSession() async {
        guard var session = currentSession else { return }
        
        isLoading = true
        
        session.completeSession()
        currentSession = session
        
        // Save session completion
        await saveSession()
        
        // Check for skin unlocks after session completion
        await SkinManager.shared.checkSkinsAfterSession()
        
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
        
        // Check for skin unlocks after session completion
        await SkinManager.shared.checkSkinsAfterSession()
        
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
