//
//  InkastBlastViewRedesigned.swift
//  Kubb Manager
//
//  Redesigned with NavigationStack and new design system for consistency
//

import SwiftUI

// MARK: - Main Inkast & Blast View (Redesigned)

struct InkastBlastViewRedesigned: View {
    @StateObject private var sessionManager: InkastBlastSessionManager
    @State private var showingTutorial = false
    @State private var showingSessionSummary = false
    @Environment(\.dismiss) private var dismiss

    init(persistenceController: PersistenceController, cloudKitManager: CloudKitManager) {
        self._sessionManager = StateObject(wrappedValue: InkastBlastSessionManager(
            persistenceController: persistenceController,
            cloudKitManager: cloudKitManager
        ))
    }

    var body: some View {
        NavigationStack {
            InkastBlastOverviewRoot(sessionManager: sessionManager)
                .navigationTitle("Inkast & Blast")
                .navigationBarTitleDisplayMode(.large)
                .navigationBarItems(
                    leading: Button("Done") {
                        dismiss()
                    },
                    trailing: Button {
                        showingTutorial = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                    }
                )
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
    }
}

// MARK: - Overview Root (Navigation Starting Point)

struct InkastBlastOverviewRoot: View {
    @ObservedObject var sessionManager: InkastBlastSessionManager
    @State private var navigateToSession = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: Spacing.sectionSpacing) {
                // Hero Section
                heroSection

                // Game Phase Selection
                if !sessionManager.isSessionActive {
                    gamePhaseSelectionSection
                } else {
                    // Navigate to active session
                    Text("Session Active")
                        .onAppear {
                            navigateToSession = true
                        }
                }
            }
            .padding(Spacing.screenPadding)
        }
        .navigationDestination(isPresented: $navigateToSession) {
            InkastBlastActiveSessionView(sessionManager: sessionManager)
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: Spacing.lg) {
            // Mode Icon
            Image("inkastblast")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 100)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium))
                .shadow(color: AppTheme.shadowMedium, radius: 8, y: 4)

            // Description
            VStack(spacing: Spacing.sm) {
                Text("Inkast & Blast Training")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.textPrimary)

                Text("Practice inkasting kubbs and clearing them efficiently")
                    .font(.body)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, Spacing.lg)
    }

    // MARK: - Game Phase Selection Section

    private var gamePhaseSelectionSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader.simple("Select Game Phase")

            VStack(spacing: Spacing.md) {
                ForEach(GamePhase.allCases, id: \.self) { phase in
                    GamePhaseCard(phase: phase) {
                        sessionManager.startNewSession(gamePhase: phase)
                        navigateToSession = true
                    }
                }
            }
        }
    }
}

// MARK: - Game Phase Card Component

struct GamePhaseCard: View {
    let phase: GamePhase
    let action: () -> Void

    private var phaseColor: Color {
        switch phase {
        case .early: return AppTheme.phaseEarly
        case .mid: return AppTheme.phaseMid
        case .end: return AppTheme.phaseEnd
        case .all: return AppTheme.primary
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                // Phase Indicator
                ZStack {
                    Circle()
                        .fill(phaseColor.opacity(0.15))
                        .frame(width: 56, height: 56)

                    Text(phase.kubbCount)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(phaseColor)
                }

                // Content
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(phase.rawValue)
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)

                    Text(phase.description)
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                        .lineLimit(2)
                }

                Spacer()

                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.textTertiary)
            }
            .padding(Spacing.md)
            .background(AppTheme.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                    .stroke(phaseColor.opacity(0.2), lineWidth: 1)
            )
            .cornerRadius(AppTheme.cornerRadiusMedium)
            .shadow(color: AppTheme.shadowLight, radius: 4, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Active Session View

struct InkastBlastActiveSessionView: View {
    @ObservedObject var sessionManager: InkastBlastSessionManager
    @StateObject private var skinManager = SkinManager.shared
    @State private var showingInkastRecording = false
    @State private var showingHitRecording = false
    @State private var showingSessionSummary = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: Spacing.sectionSpacing) {
                // Session Header with Round Info
                if let round = sessionManager.currentRound {
                    sessionHeaderCard(round: round)
                }

                // Round Phase Content
                roundPhaseContent

                // Watch Control Panel
                WatchSessionControlPanel(
                    sessionType: "Inkast & Blast",
                    onStartWatchInput: {
                        sessionManager.requestWatchInput()
                    },
                    onSendSessionState: {
                        sessionManager.sendSessionStateToWatch()
                    }
                )
            }
            .padding(Spacing.screenPadding)
        }
        .navigationTitle("Round \(sessionManager.currentRoundNumber)")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("End") {
                    sessionManager.endSession()
                    showingSessionSummary = true
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button(sessionManager.isPaused ? "Resume" : "Pause") {
                    if sessionManager.isPaused {
                        sessionManager.resumeSession()
                    } else {
                        sessionManager.pauseSession()
                    }
                }
            }
        }
        .sheet(isPresented: $showingInkastRecording) {
            InkastRecordingView(
                totalKubbs: sessionManager.currentInkastKubbs,
                skin: skinManager.selectedKubbSkin,
                onComplete: { firstAttemptOut, secondAttemptOut, neighborCount in
                    sessionManager.kubbsOutFirstAttempt = firstAttemptOut
                    sessionManager.kubbsOutSecondAttempt = secondAttemptOut
                    sessionManager.neighborKubbs = neighborCount
                    sessionManager.roundPhase = .blasting
                    showingInkastRecording = false
                }
            )
        }
        .sheet(isPresented: $showingHitRecording) {
            if let round = sessionManager.currentRound {
                VisualHitRecordingView(
                    totalKubbs: round.inkastKubbs - round.penaltyKubbs,
                    skin: skinManager.selectedKubbSkin,
                    previouslyKnockedDownKubbs: sessionManager.knockedDownKubbs,
                    onConfirm: { kubbsHit in
                        sessionManager.addBatonThrow(isHit: true, kubbsHit: kubbsHit)
                        showingHitRecording = false
                    },
                    onCancel: {
                        showingHitRecording = false
                    }
                )
            }
        }
        .sheet(isPresented: $showingSessionSummary) {
            if let session = sessionManager.currentSession {
                InkastBlastSessionSummaryView(session: session) {
                    showingSessionSummary = false
                    sessionManager.currentSession = nil
                    sessionManager.isSessionActive = false
                    dismiss()
                }
            }
        }
        .onAppear {
            if sessionManager.isSessionActive {
                sessionManager.setupWatchConnectivity()
                sessionManager.sendSessionStateToWatch()
            }
        }
    }

    // MARK: - Session Header Card

    private func sessionHeaderCard(round: InkastBlastRoundData) -> some View {
        VStack(spacing: Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Round \(sessionManager.currentRoundNumber)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.textPrimary)

                    Text(sessionManager.currentSession?.gamePhase.rawValue ?? "")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }

                Spacer()

                if sessionManager.isPaused {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "pause.circle.fill")
                            .foregroundColor(AppTheme.warning)
                        Text("Paused")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(AppTheme.warning)
                    }
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(AppTheme.warning.opacity(0.1))
                    .cornerRadius(AppTheme.cornerRadiusSmall)
                }
            }

            Divider()

            // Round Stats
            HStack(spacing: Spacing.lg) {
                StatItem(label: "Inkast", value: "\(round.inkastKubbs)")
                StatItem(label: "Target", value: "\(round.targetBatons)")
                StatItem(label: "Used", value: "\(round.batonsUsed)")
            }
        }
        .padding(Spacing.md)
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadiusMedium)
        .shadow(color: AppTheme.shadowMedium, radius: 4, y: 2)
    }

    // MARK: - Round Phase Content

    @ViewBuilder
    private var roundPhaseContent: some View {
        switch sessionManager.roundPhase {
        case .inkast:
            inkastPhaseView
        case .blasting:
            blastingPhaseView
        case .roundComplete:
            roundCompleteView
        default:
            // Other phases handled by session manager
            EmptyView()
        }
    }

    // MARK: - Inkast Phase View

    private var inkastPhaseView: some View {
        VStack(spacing: Spacing.lg) {
            VStack(spacing: Spacing.sm) {
                Image(systemName: "figure.throw")
                    .font(.system(size: 40))
                    .foregroundColor(AppTheme.inkastBlast)

                Text("Inkast Phase")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.textPrimary)
            }

            Text("Throw \(sessionManager.currentInkastKubbs) kubbs past the midline")
                .font(.body)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)

            Button("Record Results") {
                showingInkastRecording = true
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(AppTheme.primary)
            .cornerRadius(AppTheme.cornerRadiusMedium)
            .shadow(color: AppTheme.shadowMedium, radius: 4, y: 2)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadiusMedium)
        .shadow(color: AppTheme.shadowMedium, radius: 4, y: 2)
    }

    // MARK: - Blasting Phase View

    private var blastingPhaseView: some View {
        VStack(spacing: Spacing.lg) {
            VStack(spacing: Spacing.sm) {
                Text("Blasting Phase")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.textPrimary)

                if let round = sessionManager.currentRound {
                    Text("Clear the kubbs with as few batons as possible")
                        .font(.body)
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)

                    Text("Target: \(round.targetBatons) batons")
                        .font(.headline)
                        .foregroundColor(AppTheme.primary)

                    // Baton visual
                    BatonRow(
                        skin: skinManager.selectedBatonSkin,
                        currentBaton: round.batonsUsed + 1,
                        totalBatons: 6
                    )

                    // Hit/Miss Buttons
                    HStack(spacing: Spacing.xl) {
                        // Miss Button
                        Button(action: {
                            sessionManager.addBatonThrow(isHit: false)
                        }) {
                            VStack(spacing: Spacing.md) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.white)

                                Text("MISS")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            .frame(width: 140, height: 140)
                            .background(AppTheme.error)
                            .cornerRadius(AppTheme.cornerRadiusLarge)
                            .shadow(color: AppTheme.shadowMedium, radius: 4, y: 2)
                        }

                        // Hit Button
                        Button(action: {
                            showingHitRecording = true
                        }) {
                            VStack(spacing: Spacing.md) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.white)

                                Text("HIT")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            .frame(width: 140, height: 140)
                            .background(AppTheme.success)
                            .cornerRadius(AppTheme.cornerRadiusLarge)
                            .shadow(color: AppTheme.shadowMedium, radius: 4, y: 2)
                        }
                    }
                }
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadiusMedium)
        .shadow(color: AppTheme.shadowMedium, radius: 4, y: 2)
    }

    // MARK: - Round Complete View

    private var roundCompleteView: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.success)

            Text("Round Complete!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.success)

            if let round = sessionManager.currentRound {
                VStack(spacing: Spacing.sm) {
                    Text("Used \(round.batonsUsed) batons")
                        .font(.headline)

                    if round.batonsUsed <= round.targetBatons {
                        Text("Great job! You met your target!")
                            .font(.body)
                            .foregroundColor(AppTheme.success)
                    } else {
                        Text("Keep practicing to beat your target")
                            .font(.body)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }

                Button("Next Round") {
                    sessionManager.startNewRound()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(AppTheme.primary)
                .cornerRadius(AppTheme.cornerRadiusMedium)
                .shadow(color: AppTheme.shadowMedium, radius: 4, y: 2)
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadiusMedium)
        .shadow(color: AppTheme.shadowMedium, radius: 4, y: 2)
    }
}

// MARK: - Helper Components

struct StatItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: Spacing.xs) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.textPrimary)

            Text(label)
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
        }
    }
}

// MARK: - GamePhase Extension

extension GamePhase {
    var kubbCount: String {
        switch self {
        case .early: return "1-3"
        case .mid: return "4-7"
        case .end: return "8-10"
        case .all: return "All"
        }
    }
}

// MARK: - Preview

#Preview {
    InkastBlastViewRedesigned(
        persistenceController: PersistenceController.preview,
        cloudKitManager: CloudKitManager.shared
    )
}
