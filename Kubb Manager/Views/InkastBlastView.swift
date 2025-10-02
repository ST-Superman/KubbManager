//
//  InkastBlastView.swift
//  Kubb Manager
//
//  Created by Scott Thompson on 1/15/25.
//

import SwiftUI

struct InkastBlastView: View {
    @StateObject private var sessionManager: InkastBlastSessionManager
    @State private var showingTutorial = false
    @State private var showingGamePhaseSelection = false
    @State private var showingSessionSummary = false
    @State private var selectedGamePhase: GamePhase = .early
    @State private var showingHitRecording = false
    @State private var showingInkastRecording = false
    @StateObject private var skinManager = SkinManager.shared
    @Environment(\.dismiss) private var dismiss
    
    init(persistenceController: PersistenceController, cloudKitManager: CloudKitManager) {
        self._sessionManager = StateObject(wrappedValue: InkastBlastSessionManager(
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
                            // Game Phase Selection
                            gamePhaseSelectionView
                        } else {
                            // Active Session View
                            activeSessionView
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Inkast & Blast")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back to Main Menu") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
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
                }
            }
        }
        .sheet(isPresented: $showingTutorial) {
            InkastBlastTutorialView()
        }
        .sheet(isPresented: $showingSessionSummary) {
            if let session = sessionManager.currentSession {
                InkastBlastSessionSummaryView(session: session) {
                    showingSessionSummary = false
                    sessionManager.currentSession = nil
                    sessionManager.isSessionActive = false
                }
            }
        }
    }
    
    // MARK: - Game Phase Selection View
    
    private var gamePhaseSelectionView: some View {
        VStack(spacing: 24) {
            // Header Card
            VStack(spacing: 16) {
                Image("inkastblast")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(spacing: 8) {
                    Text("Inkast & Blast Training")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Practice inkasting kubbs and clearing them efficiently")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            
            // Game Phase Selection
            VStack(alignment: .leading, spacing: 16) {
                Text("Select Game Phase")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(spacing: 12) {
                    ForEach(GamePhase.allCases, id: \.self) { phase in
                        Button(action: {
                            selectedGamePhase = phase
                            sessionManager.startNewSession(gamePhase: phase)
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(phase.rawValue)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text(phase.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
    
    // MARK: - Active Session View
    
    private var activeSessionView: some View {
        VStack(spacing: 20) {
            // Session Header
            sessionHeaderView
            
            // Current Round Info
            if let round = sessionManager.currentRound {
                currentRoundView(round: round)
            }
            
            // Round Phase Content
            roundPhaseView
            
            Spacer()
        }
    }
    
    private var sessionHeaderView: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Round \(sessionManager.currentRoundNumber)")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(sessionManager.currentSession?.gamePhase.rawValue ?? "")
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
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private func currentRoundView(round: InkastBlastRoundData) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("Inkast \(round.inkastKubbs) kubbs")
                    .font(.headline)
                
                Spacer()
                
                if round.isComplete {
                    Text("Complete")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(6)
                }
            }
            
            if round.isComplete {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Target: \(round.targetBatons) batons")
                        Text("Used: \(round.batonsUsed) batons")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text(round.performanceVsTarget > 0 ? "+\(round.performanceVsTarget)" : "\(round.performanceVsTarget)")
                            .font(.headline)
                            .foregroundColor(round.performanceVsTarget > 0 ? .green : round.performanceVsTarget < 0 ? .red : .primary)
                        Text("vs Target")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    @ViewBuilder
    private var roundPhaseView: some View {
        switch sessionManager.roundPhase {
        case .inkast:
            inkastPhaseView
        case .firstAttemptResults:
            firstAttemptResultsView
        case .secondAttempt:
            secondAttemptView
        case .secondAttemptResults:
            secondAttemptResultsView
        case .neighborCheck:
            neighborCheckView
        case .blasting:
            blastingPhaseView
        case .roundComplete:
            roundCompleteView
        }
    }
    
    // MARK: - Phase Views
    
    private var inkastPhaseView: some View {
        VStack(spacing: 20) {
            Text("Inkast Phase")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Throw \(sessionManager.currentInkastKubbs) kubbs past the midline")
                .font(.body)
                .multilineTextAlignment(.center)
            
            Button("Record Results") {
                showingInkastRecording = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .sheet(isPresented: $showingInkastRecording) {
            InkastRecordingView(
                totalKubbs: sessionManager.currentInkastKubbs,
                skin: skinManager.selectedKubbSkin,
                onFirstAttemptResults: { outCount in
                    sessionManager.kubbsOutFirstAttempt = outCount
                    sessionManager.roundPhase = outCount > 0 ? .secondAttempt : .neighborCheck
                    showingInkastRecording = false
                },
                onSecondAttemptResults: { outCount in
                    sessionManager.kubbsOutSecondAttempt = outCount
                    sessionManager.roundPhase = .neighborCheck
                    showingInkastRecording = false
                },
                onNeighborResults: { neighborCount in
                    sessionManager.neighborKubbs = neighborCount
                    sessionManager.roundPhase = .blasting
                    showingInkastRecording = false
                }
            )
        }
    }
    
    private var firstAttemptResultsView: some View {
        VStack(spacing: 20) {
            Text("First Attempt Results")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("How many kubbs went out of bounds?")
                .font(.body)
                .multilineTextAlignment(.center)
            
            Stepper("Out of bounds: \(sessionManager.kubbsOutFirstAttempt)", 
                   value: $sessionManager.kubbsOutFirstAttempt, 
                   in: 0...sessionManager.currentInkastKubbs)
            
            Button(sessionManager.kubbsOutFirstAttempt > 0 ? "Second Attempt" : "Check Neighbors") {
                if sessionManager.kubbsOutFirstAttempt > 0 {
                    sessionManager.roundPhase = .secondAttempt
                } else {
                    sessionManager.roundPhase = .neighborCheck
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var secondAttemptView: some View {
        VStack(spacing: 20) {
            Text("Second Attempt")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Re-throw the \(sessionManager.kubbsOutFirstAttempt) kubbs that were out of bounds")
                .font(.body)
                .multilineTextAlignment(.center)
            
            Button("Record Second Attempt") {
                sessionManager.roundPhase = .secondAttemptResults
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var secondAttemptResultsView: some View {
        VStack(spacing: 20) {
            Text("Second Attempt Results")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("How many kubbs are still out of bounds?")
                .font(.body)
                .multilineTextAlignment(.center)
            
            Stepper("Still out: \(sessionManager.kubbsOutSecondAttempt)", 
                   value: $sessionManager.kubbsOutSecondAttempt, 
                   in: 0...sessionManager.kubbsOutFirstAttempt)
            
            Button("Check Neighbors") {
                sessionManager.roundPhase = .neighborCheck
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var neighborCheckView: some View {
        VStack(spacing: 20) {
            Text("Neighbor Check")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Any kubbs landed on top of each other?")
                .font(.body)
                .multilineTextAlignment(.center)
            
            Stepper("Neighbor kubbs: \(sessionManager.neighborKubbs)", 
                   value: $sessionManager.neighborKubbs, 
                   in: 0...sessionManager.currentInkastKubbs)
            
            Button("Start Blasting") {
                sessionManager.roundPhase = .blasting
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var blastingPhaseView: some View {
        VStack(spacing: 20) {
            Text("Blasting Phase")
                .font(.title2)
                .fontWeight(.bold)
            
            if let round = sessionManager.currentRound {
                Text("Stand up the kubbs and clear them with as few batons as possible")
                    .font(.body)
                    .multilineTextAlignment(.center)
                
                Text("Target: \(round.targetBatons) batons")
                    .font(.headline)
                    .foregroundColor(.blue)
                
                // Baton visual
                BatonRow(
                    skin: skinManager.selectedBatonSkin,
                    currentBaton: round.batonsUsed + 1,
                    totalBatons: 6
                )
                
                HStack(spacing: 20) {
                    Button("Miss") {
                        sessionManager.addBatonThrow(isHit: false)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    
                    Button("Hit") {
                        showingHitRecording = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .sheet(isPresented: $showingHitRecording) {
            if let round = sessionManager.currentRound {
                HitRecordingView(
                    kubbs: createKubbStates(for: round),
                    penaltyKubbs: createPenaltyKubbStates(for: round),
                    skin: skinManager.selectedKubbSkin,
                    onKubbTap: { index in
                        // Handle kubb tap
                    },
                    onPenaltyKubbTap: { index in
                        // Handle penalty kubb tap
                    },
                    onConfirm: { kubbsHit, penaltyKubbsHit in
                        // Record hit with knocked down kubbs
                        let totalHitCount = kubbsHit + penaltyKubbsHit
                        sessionManager.addBatonThrow(isHit: true, kubbsHit: totalHitCount)
                        showingHitRecording = false
                    },
                    onCancel: {
                        showingHitRecording = false
                    }
                )
            }
        }
    }
    
    private var roundCompleteView: some View {
        VStack(spacing: 20) {
            Text("Round Complete!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.green)
            
            if let round = sessionManager.currentRound {
                VStack(spacing: 8) {
                    Text("Used \(round.batonsUsed) batons")
                    Text("Target was \(round.targetBatons) batons")
                    
                    if round.performanceVsTarget > 0 {
                        Text("+\(round.performanceVsTarget) under target! 🎉")
                            .foregroundColor(.green)
                    } else if round.performanceVsTarget < 0 {
                        Text("\(round.performanceVsTarget) over target")
                            .foregroundColor(.red)
                    } else {
                        Text("Exactly on target! 🎯")
                            .foregroundColor(.blue)
                    }
                }
            }
            
            HStack(spacing: 16) {
                Button("Next Round") {
                    sessionManager.startNextRound()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                Button("End Session") {
                    sessionManager.endSession()
                    showingSessionSummary = true
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Helper Functions
    
    private func createKubbStates(for round: InkastBlastRoundData) -> [KubbState] {
        let totalKubbs = round.inkastKubbs - round.penaltyKubbs
        let previouslyKnockedDown = round.totalKubbsKnockedDown
        
        return Array(0..<totalKubbs).map { index in
            let isPreviouslyKnockedDown = index < previouslyKnockedDown
            let isCurrentlyTappable = index >= previouslyKnockedDown
            
            return KubbState(
                isKnockedDown: isPreviouslyKnockedDown,
                isTappable: isCurrentlyTappable
            )
        }
    }
    
    private func createPenaltyKubbStates(for round: InkastBlastRoundData) -> [KubbState] {
        return Array(0..<round.penaltyKubbs).map { _ in
            KubbState(
                isKnockedDown: false,
                isTappable: true
            )
        }
    }
}

#Preview {
    InkastBlastView(
        persistenceController: PersistenceController.preview,
        cloudKitManager: CloudKitManager.shared
    )
}
