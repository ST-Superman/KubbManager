//
//  FullGameSimView.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 1/15/25.
//

import SwiftUI

struct FullGameSimView: View {
    @StateObject private var sessionManager: FullGameSimSessionManager
    @State private var showingTutorial = false
    @State private var showingSessionSummary = false
    @State private var showingHitRecording = false
    @State private var showingInkastRecording = false
    @State private var showingFirstAttemptResults = false
    @State private var showingSecondAttemptResults = false
    @State private var showingNeighborCheck = false
    @State private var showingRecoveryAlert = false
    @State private var showingResumeReview = false
    @StateObject private var skinManager = SkinManager.shared
    @Environment(\.dismiss) private var dismiss
    
    init(persistenceController: PersistenceController, cloudKitManager: CloudKitManager) {
        self._sessionManager = StateObject(wrappedValue: FullGameSimSessionManager(
            persistenceController: persistenceController,
            cloudKitManager: cloudKitManager
        ))
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 24) {
                        if !sessionManager.isSessionActive {
                            // Start Session View
                            startSessionView
                        } else {
                            // Active Session View
                            activeSessionView
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Full Game Sim")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(
                leading: Button("Dismiss") {
                    // If there's an active session, pause it before dismissing
                    if sessionManager.isSessionActive && !sessionManager.isPaused {
                        sessionManager.pauseSession()
                    }
                    dismiss()
                },
                trailing: Menu {
                    Button("Tutorial") {
                        showingTutorial = true
                    }
                    
                    if sessionManager.isSessionActive {
                        Button(sessionManager.isPaused ? "Resume" : "Pause") {
                            if sessionManager.isPaused {
                                sessionManager.resumeSession()
                            } else {
                                sessionManager.pauseSession()
                            }
                        }
                        
                        Button("End Session") {
                            sessionManager.endSession()
                            showingSessionSummary = true
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            )
        }
        .sheet(isPresented: $showingTutorial) {
            FullGameSimTutorialView()
        }
        .sheet(isPresented: $showingSessionSummary) {
            if let session = sessionManager.currentSession {
                FullGameSimSessionSummaryView(session: session) {
                    showingSessionSummary = false
                    sessionManager.currentSession = nil
                    sessionManager.isSessionActive = false
                }
            }
        }
        .sheet(isPresented: $showingResumeReview) {
            if let session = sessionManager.currentSession {
                FullGameSimResumeReviewView(
                    session: session,
                    onResume: {
                        showingResumeReview = false
                        sessionManager.resumeIncompleteSession()
                    },
                    onCancel: {
                        showingResumeReview = false
                    }
                )
            }
        }
        .alert("Incomplete Full Game Sim", isPresented: $showingRecoveryAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Review & Resume") {
                showingResumeReview = true
            }
            Button("Abandon", role: .destructive) {
                Task {
                    await sessionManager.abandonIncompleteSession()
                }
            }
        } message: {
            if let session = sessionManager.currentSession {
                Text("You have an incomplete game from \(session.createdAt.formatted(date: .abbreviated, time: .shortened)). Round \(session.currentRound) • Team \(session.currentAttackingTeam) attacking.")
            }
        }
        .task {
            // Load incomplete session first, then check if we should show alert
            await sessionManager.loadIncompleteSession()
            checkForIncompleteSession()
        }
    }
    
    private func checkForIncompleteSession() {
        print("🔍 Checking for incomplete session...")
        print("🔍 Has incomplete session: \(sessionManager.hasIncompleteSession())")
        print("🔍 Should show alert: \(sessionManager.shouldShowRecoveryAlert())")
        if let session = sessionManager.currentSession {
            print("🔍 Current session: \(session.id), isComplete: \(session.isComplete), isPaused: \(session.isPaused)")
        } else {
            print("🔍 No current session found")
        }
        
        if sessionManager.shouldShowRecoveryAlert() {
            print("✅ Showing recovery alert")
            showingRecoveryAlert = true
        } else {
            print("❌ Not showing recovery alert")
        }
    }
    
    // MARK: - Start Session View
    
    private var startSessionView: some View {
        VStack(spacing: 24) {
            // Header Card
            VStack(spacing: 16) {
                Image("king")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(spacing: 8) {
                    Text("Full Game Sim")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Complete kubb game simulation with inkast, blast, and 8-meter phases")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            
            // Game Rules
            VStack(alignment: .leading, spacing: 16) {
                Text("How it Works")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(alignment: .leading, spacing: 12) {
                    GameRuleRow(
                        round: "Setup",
                        description: "Full kubb pitch"
                    )
                    
                    GameRuleRow(
                        round: "Play",
                        description: "Play a standard game against yourself"
                    )
                    
                    GameRuleRow(
                        round: "Stats",
                        description: "Kubb Manager will track your stats for Inkasting, blasting, and 8 meter throws"
                    )
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
            
            // Start Button
            Button(action: {
                sessionManager.startNewSession()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "play.fill")
                        .font(.title2)
                    Text("Start Full Game Sim")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .padding(.horizontal, 24)
                .background(Color.blue)
                .cornerRadius(16)
            }
        }
    }
    
    // MARK: - Active Session View
    
    private var activeSessionView: some View {
        VStack(spacing: 20) {
            // Session Header
            sessionHeaderView
            
            // Phase Content
            phaseContentView
            
            Spacer()
            
            // Watch Control Panel (at bottom)
            WatchSessionControlPanel(
                sessionType: "Full Game Sim",
                onStartWatchInput: {
                    sessionManager.requestWatchInput()
                },
                onSendSessionState: {
                    sessionManager.sendSessionStateToWatch()
                }
            )
        }
        .onAppear {
            // Ensure watch connectivity is set up when active session view appears
            // This handles cases where the session was loaded but not formally "resumed"
            if sessionManager.isSessionActive {
                sessionManager.setupWatchConnectivity()
                sessionManager.sendSessionStateToWatch()
            }
        }
    }
    
    private var sessionHeaderView: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Round \(sessionManager.currentRoundNumber)")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(sessionManager.currentRoundNumber % 2 == 1 ? "Team 1 attacking" : "Team 2 attacking")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if sessionManager.isPaused {
                    HStack(spacing: 4) {
                        Image(systemName: "pause.circle.fill")
                            .foregroundColor(.orange)
                        Text("Paused")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            // A-Line Status Indicator
            if let round = sessionManager.currentRound, sessionManager.currentRoundNumber > 1 {
                if round.hasALine {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.yellow)
                        Text("A-Line Active!")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        if let phase = round.gamePhaseWhenALineAwarded {
                            Text("(earned in \(phase.rawValue.capitalized) phase)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.yellow.opacity(0.2))
                    .cornerRadius(8)
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "ruler")
                            .foregroundColor(.gray)
                        Text("Attacking from Baseline")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
            
            // Show both teams' baseline kubb counts
            if let session = sessionManager.currentSession {
                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("Team 1")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                        Text("\(session.team1BaselineKubbs) baseline")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if session.team1UnclearedKubbs > 0 {
                            Text("\(session.team1UnclearedKubbs) uncleared")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    VStack(spacing: 4) {
                        Text("Team 2")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                        Text("\(session.team2BaselineKubbs) baseline")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if session.team2UnclearedKubbs > 0 {
                            Text("\(session.team2UnclearedKubbs) uncleared")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    
    @ViewBuilder
    private var phaseContentView: some View {
        if let round = sessionManager.currentRound {
            switch sessionManager.currentPhase {
            case .inkast:
                inkastPhaseView(round: round)
            case .attacking:
                attackingPhaseView(round: round)
            case .roundComplete:
                Text("Round Complete")
                    .foregroundColor(.secondary)
            }
        } else {
            Text("No active round")
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Phase Views
    
    private func inkastPhaseView(round: FullGameSimRoundStruct) -> some View {
        VStack(spacing: 20) {
            Text("Inkast Phase")
                .font(.title2)
                .fontWeight(.bold)
            
            if round.inkastData.inkastKubbs > 0 {
                Text("Throw \(round.inkastData.inkastKubbs) kubbs past the midline")
                    .font(.body)
                    .multilineTextAlignment(.center)
                
                Button("Record Results") {
                    showingInkastRecording = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            } else {
                Text("No kubbs to inkast this round")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button("Continue to Blast Phase") {
                    sessionManager.completeInkastPhase()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .sheet(isPresented: $showingInkastRecording) {
            InkastRecordingView(
                totalKubbs: round.inkastData.inkastKubbs,
                skin: skinManager.selectedKubbSkin,
                onComplete: { firstAttemptOut, secondAttemptOut, neighborCount in
                    sessionManager.kubbsOutFirstAttempt = firstAttemptOut
                    sessionManager.kubbsOutSecondAttempt = secondAttemptOut
                    sessionManager.neighborKubbs = neighborCount
                    sessionManager.completeInkastPhase()
                    showingInkastRecording = false
                }
            )
        }
    }
    
    
    private func attackingPhaseView(round: FullGameSimRoundStruct) -> some View {
        VStack(spacing: 20) {
            // Pitch Visual
            if let session = sessionManager.currentSession {
                FullGamePitchVisualView(
                    roundData: round,
                    sessionData: session,
                    skin: skinManager.selectedKubbSkin
                )
            }
            
            // Baton visual - only show batons for current round
            BatonRow(
                skin: skinManager.selectedBatonSkin,
                currentBaton: getCurrentBatonForAttackingPhase(round),
                totalBatons: getBatonLimitForRound(round.roundNumber)
            )
            
            HStack(spacing: 30) {
                Button(action: {
                    // Record miss - use appropriate method based on what kubbs are available
                    if hasFieldKubbsRemaining(round) {
                        sessionManager.addBlastBatonThrow(isHit: false)
                    } else {
                        sessionManager.addEightMeterBatonThrow(isHit: false)
                    }
                }) {
                    VStack(spacing: 12) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                        
                        Text("MISS")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .frame(width: 140, height: 140)
                    .background(Color.red)
                    .cornerRadius(20)
                }
                
                Button(action: {
                    showingHitRecording = true
                }) {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                        
                        Text("HIT")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .frame(width: 140, height: 140)
                    .background(Color.green)
                    .cornerRadius(20)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .sheet(isPresented: $showingHitRecording) {
            if let session = sessionManager.currentSession {
                FullGameHitRecordingView(
                    roundData: round,
                    sessionData: session,
                    skin: skinManager.selectedKubbSkin,
                    onConfirm: { fieldKubbsHit, baselineKubbsHit, kingHit in
                        // Record the hit with proper statistics tracking
                        sessionManager.addBlastBatonThrowWithFieldAndBaseline(
                            fieldKubbsHit: fieldKubbsHit,
                            baselineKubbsHit: baselineKubbsHit,
                            kingHit: kingHit
                        )
                        showingHitRecording = false
                    },
                    onCancel: {
                        showingHitRecording = false
                    }
                )
            }
        }
    }
    
    // MARK: - Helper Functions
    
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
    
    private func getCurrentBatonForAttackingPhase(_ round: FullGameSimRoundStruct) -> Int {
        // For Round 1, use 8-meter batons only
        if round.roundNumber == 1 {
            return round.eightMeterData.batonsUsed + 1
        }
        
        // For other rounds, use combined baton count for entire attacking phase
        let totalBatonsUsed = round.blastData.batonsUsed + round.eightMeterData.batonsUsed
        return totalBatonsUsed + 1
    }
    
    private func hasFieldKubbsRemaining(_ round: FullGameSimRoundStruct) -> Bool {
        return round.inkastData.totalKubbsInBounds - round.blastData.kubbsClearedFirstThrow > 0
    }
    
    
}

// MARK: - Supporting Views

struct GameRuleRow: View {
    let round: String
    let description: String
    
    var body: some View {
        HStack {
            Text(round)
                .font(.headline)
                .foregroundColor(.blue)
                .frame(width: 80, alignment: .leading)
            
            Text(description)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

struct FullGameSimTutorialView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    Text("Full Game Sim Tutorial")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Learn how to play the complete kubb game simulation")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    // Tutorial content would go here
                    Text("Tutorial content coming soon...")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationTitle("Tutorial")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    dismiss()
                }
            )
        }
    }
}

struct FullGameSimResumeReviewView: View {
    let session: FullGameSimSessionStruct
    let onResume: () -> Void
    let onCancel: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.purple)
                        
                        Text("Resume Game")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Review the current game state before continuing")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    
                    // Game State Card
                    VStack(spacing: 16) {
                        Text("Game Status")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            InfoCard(
                                title: "Current Round",
                                value: "\(session.currentRound)",
                                icon: "repeat",
                                color: .blue
                            )
                            
                            InfoCard(
                                title: "Attacking Team",
                                value: "Team \(session.currentAttackingTeam)",
                                icon: "figure.run",
                                color: .green
                            )
                        }
                        
                        // Baseline Kubbs Remaining
                        VStack(spacing: 12) {
                            Text("Baseline Kubbs Remaining")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack(spacing: 20) {
                                // Team 1
                                VStack(spacing: 8) {
                                    Text("Team 1")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    
                                    HStack(spacing: 4) {
                                        ForEach(0..<5, id: \.self) { index in
                                            Circle()
                                                .fill(index < session.team1BaselineKubbs ? Color.blue : Color.gray.opacity(0.3))
                                                .frame(width: 30, height: 30)
                                                .overlay(
                                                    Image(systemName: "cube.fill")
                                                        .font(.caption2)
                                                        .foregroundColor(.white)
                                                )
                                        }
                                    }
                                    
                                    Text("\(session.team1BaselineKubbs)/5")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Divider()
                                
                                // Team 2
                                VStack(spacing: 8) {
                                    Text("Team 2")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    
                                    HStack(spacing: 4) {
                                        ForEach(0..<5, id: \.self) { index in
                                            Circle()
                                                .fill(index < session.team2BaselineKubbs ? Color.orange : Color.gray.opacity(0.3))
                                                .frame(width: 30, height: 30)
                                                .overlay(
                                                    Image(systemName: "cube.fill")
                                                        .font(.caption2)
                                                        .foregroundColor(.white)
                                                )
                                        }
                                    }
                                    
                                    Text("\(session.team2BaselineKubbs)/5")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            dismiss()
                            onResume()
                        }) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Resume Game")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .cornerRadius(12)
                        }
                        
                        Button(action: {
                            dismiss()
                            onCancel()
                        }) {
                            Text("Cancel")
                                .font(.headline)
                                .foregroundColor(.purple)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Resume Game")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct InfoCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct FullGameSimSessionSummaryView: View {
    let session: FullGameSimSessionStruct
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    Text("Session Complete!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    // Session statistics would go here
                    Text("Session statistics coming soon...")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationTitle("Session Summary")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    onDismiss()
                }
            )
        }
    }
}

#Preview {
    FullGameSimView(
        persistenceController: PersistenceController.preview,
        cloudKitManager: CloudKitManager.shared
    )
}
