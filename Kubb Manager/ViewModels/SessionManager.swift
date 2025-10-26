//
//  SessionManager.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 9/23/25.
//

import Foundation
import Combine

// MARK: - Practice Session Management
// This class manages the current practice session state and handles all session operations
// It coordinates between the UI and CloudKit for data persistence and synchronization

@MainActor
class SessionManager: ObservableObject {
    // MARK: - Published Properties
    // These properties automatically update the UI when their values change
    @Published var currentSession: PracticeSession?  // The currently active practice session
    @Published var isSessionActive: Bool = false     // Whether a session is currently running
    @Published var isLoading: Bool = false           // Whether an async operation is in progress
    @Published var errorMessage: String?             // Error message to display to user
    
    // MARK: - Dependencies
    private let cloudKitManager = CloudKitManager.shared  // Handles CloudKit sync operations
    private var cancellables = Set<AnyCancellable>()      // Manages Combine subscriptions
    
    // MARK: - Initialization
    
    /// Initializes the SessionManager and loads any incomplete session from storage
    init() {
        // Load any incomplete session asynchronously on startup
        // This allows users to resume their practice if they closed the app
        Task {
            await loadIncompleteSession()
        }
    }
    
    // MARK: - Session Management
    
    /// Starts a new practice session with the specified target
    /// - Parameter target: The number of batons the user wants to throw
    func startNewSession(target: Int) async {
        isLoading = true
        errorMessage = nil
        
        do {
            print("🚀 Starting new practice session with target: \(target)")
            
            // Create new session with enhanced logging
            let newSession = PracticeSession(target: target)
            print("📝 Created session with ID: \(newSession.id)")
            
            // Pre-save duplicate check to prevent CloudKit conflicts
            await performPreSaveDuplicateCheck(for: newSession)
            
            // Update UI state
            currentSession = newSession
            isSessionActive = true
            
            // Setup watch connectivity and notify watch
            setupWatchConnectivity()
            notifyWatchSessionStarted()
            sendSessionStateToWatch()
            
            // Save to CloudKit for synchronization across devices
            try await cloudKitManager.saveSession(newSession)
            print("✅ Successfully started and saved new session: \(newSession.id)")
            isLoading = false
        } catch {
            // Handle any errors that occur during session creation
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
                // Apply auto-completion: sessions from previous days are automatically completed
                let autoCompletedSession = incompleteSession.withAutoCompletion()
                
                // Only set as current session if it's still incomplete (i.e., from today)
                if autoCompletedSession.isIncomplete {
                    currentSession = autoCompletedSession
                    isSessionActive = true
                    
                    // Don't setup watch connectivity yet - wait until user actually resumes
                    // setupWatchConnectivity() will be called in resumeSession()
                } else {
                    // Session was auto-completed, save it and clear current session
                    try await cloudKitManager.saveSession(autoCompletedSession)
                    currentSession = nil
                    isSessionActive = false
                    print("🔄 Auto-completed session from previous day: \(autoCompletedSession.id)")
                }
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
        
        // Don't add batons if the current round is already complete (more than 6 throws)
        // Allow the 6th baton to be processed to complete the round
        if let currentRound = session.currentRound, currentRound.totalBatonThrows >= 6 {
            return
        }
        
        session.addBatonResult(isHit: isHit)
        currentSession = session
        
        // Save when round is complete OR when target is reached
        if let currentRound = session.currentRound, currentRound.isRoundComplete {
            await saveSession()
        } else if session.isTargetReached {
            // Save immediately when target is reached to ensure CloudKit is updated
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
    
    func pauseSession() async {
        guard var session = currentSession else { return }
        
        session.pauseSession()
        currentSession = session
        
        // Save session state
        await saveSession()
        
        isSessionActive = false
    }
    
    func resumeSession() async {
        guard let session = currentSession else { return }
        
        // Only resume if session is paused and from today
        guard session.isPaused && Calendar.current.isDateInToday(session.date) else { return }
        
        var updatedSession = session
        updatedSession.resumeSession()
        currentSession = updatedSession
        
        // Setup watch connectivity when resuming
        setupWatchConnectivity()
        notifyWatchSessionStarted()
        sendSessionStateToWatch()
        
        // Save session state
        await saveSession()
        
        isSessionActive = true
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

    /// Undoes the last baton throw in the current round
    func undoLastBatonThrow() async {
        guard var session = currentSession else { return }

        session.undoLastBatonThrow()
        currentSession = session

        // Save the undo action
        await saveSession()
    }

    func startNextRound() async {
        guard var session = currentSession else { return }

        session.startNextRound()
        currentSession = session

        // Save the new round
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
    
    func resumeIncompleteSession() {
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
    
    func hasPausedSession() -> Bool {
        return currentSession?.isPaused ?? false
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
