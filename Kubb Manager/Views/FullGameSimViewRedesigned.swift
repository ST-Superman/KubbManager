//
//  FullGameSimViewRedesigned.swift
//  Kubb Manager
//
//  Redesigned Full Game Sim using NavigationStack pattern and design system
//

import SwiftUI

// MARK: - Main View

struct FullGameSimViewRedesigned: View {
    @StateObject private var sessionManager: FullGameSimSessionManager
    @StateObject private var skinManager = SkinManager.shared
    @State private var showingTutorial = false
    @State private var navigateToSession = false
    @Environment(\.dismiss) private var dismiss

    init(persistenceController: PersistenceController, cloudKitManager: CloudKitManager) {
        self._sessionManager = StateObject(wrappedValue: FullGameSimSessionManager(
            persistenceController: persistenceController,
            cloudKitManager: cloudKitManager
        ))
    }

    var body: some View {
        NavigationStack {
            FullGameSimOverviewRoot(
                sessionManager: sessionManager,
                navigateToSession: $navigateToSession
            )
            .navigationTitle("Full Game Sim")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(
                leading: Button("Done") {
                    if sessionManager.isSessionActive && !sessionManager.isPaused {
                        sessionManager.pauseSession()
                    }
                    dismiss()
                },
                trailing: Button {
                    showingTutorial = true
                } label: {
                    Image(systemName: "questionmark.circle")
                }
            )
            .navigationDestination(isPresented: $navigateToSession) {
                FullGameSimActiveSessionView(sessionManager: sessionManager)
            }
            .sheet(isPresented: $showingTutorial) {
                FullGameSimTutorialView()
            }
        }
    }
}

// MARK: - Overview Root

struct FullGameSimOverviewRoot: View {
    @ObservedObject var sessionManager: FullGameSimSessionManager
    @Binding var navigateToSession: Bool
    @State private var showingRecoveryAlert = false
    @State private var showingResumeReview = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: Spacing.sectionSpacing) {
                // Hero Section
                heroSection

                // If not active, show start options
                if !sessionManager.isSessionActive {
                    // How it Works
                    howItWorksSection

                    // Start Button
                    startButtonSection
                } else {
                    // Navigate to active session
                    Text("")
                        .onAppear {
                            navigateToSession = true
                        }
                }
            }
            .padding(Spacing.screenPadding)
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
        .sheet(isPresented: $showingResumeReview) {
            if let session = sessionManager.currentSession {
                FullGameSimResumeReviewView(
                    session: session,
                    onResume: {
                        showingResumeReview = false
                        sessionManager.resumeIncompleteSession()
                        navigateToSession = true
                    },
                    onCancel: {
                        showingResumeReview = false
                    }
                )
            }
        }
        .task {
            await sessionManager.loadIncompleteSession()
            if sessionManager.shouldShowRecoveryAlert() {
                showingRecoveryAlert = true
            }
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: Spacing.lg) {
            // Icon
            Image("king")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 120)
                .shadow(color: AppTheme.shadowMedium, radius: 8, y: 4)

            // Title & Description
            VStack(spacing: Spacing.sm) {
                Text("Full Game Sim")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.textPrimary)

                Text("Complete kubb game simulation with inkast, blast, and 8-meter phases")
                    .font(.body)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadiusLarge)
        .shadow(color: AppTheme.shadowMedium, radius: 8, y: 4)
    }

    // MARK: - How it Works Section

    private var howItWorksSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader.simple("How it Works")

            VStack(spacing: Spacing.md) {
                GamePhaseInfoCard(
                    title: "Setup",
                    description: "Full kubb pitch with 5 baseline kubbs per team",
                    icon: "square.grid.3x3",
                    color: AppTheme.primary
                )

                GamePhaseInfoCard(
                    title: "Play",
                    description: "Play a standard game against yourself with realistic rules",
                    icon: "figure.play",
                    color: AppTheme.success
                )

                GamePhaseInfoCard(
                    title: "Stats",
                    description: "Track your inkasting, blasting, and 8-meter throw statistics",
                    icon: "chart.bar.fill",
                    color: AppTheme.fullGameSim
                )
            }
        }
    }

    // MARK: - Start Button Section

    private var startButtonSection: some View {
        Button(action: {
            sessionManager.startNewSession()
            navigateToSession = true
        }) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "play.fill")
                    .font(.title2)
                Text("Start Full Game Sim")
                    .font(.title3)
                    .fontWeight(.bold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.lg)
            .background(AppTheme.fullGameSim)
            .cornerRadius(AppTheme.cornerRadiusLarge)
            .shadow(color: AppTheme.shadowMedium, radius: 8, y: 4)
        }
    }
}

// MARK: - Active Session View

struct FullGameSimActiveSessionView: View {
    @ObservedObject var sessionManager: FullGameSimSessionManager
    @StateObject private var skinManager = SkinManager.shared
    @State private var showingSessionSummary = false
    @State private var showingHitRecording = false
    @State private var showingInkastRecording = false
    @State private var showingSendToWatchSheet = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .top) {
            AppTheme.surface.ignoresSafeArea()

            VStack(spacing: 0) {
                // Sticky Header
                stickyHeaderView

                // Scrollable Content
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: Spacing.sectionSpacing) {
                        // Phase Content
                        phaseContentView

                        // Throw Controls
                        throwControlsCard
                    }
                    .padding(Spacing.screenPadding)
                }
            }
        }
        .navigationTitle("Round \(sessionManager.currentRoundNumber)")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(
            leading: Button("Back") {
                if sessionManager.isSessionActive && !sessionManager.isPaused {
                    sessionManager.pauseSession()
                }
                dismiss()
            },
            trailing: HStack(spacing: 12) {
                WatchIconButton {
                    showingSendToWatchSheet = true
                }

                Menu {
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
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        )
        .sheet(isPresented: $showingSessionSummary) {
            if let session = sessionManager.currentSession {
                FullGameSimSessionSummaryView(session: session) {
                    showingSessionSummary = false
                    sessionManager.currentSession = nil
                    sessionManager.isSessionActive = false
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showingSendToWatchSheet) {
            SendToWatchSheet(
                isPresented: $showingSendToWatchSheet,
                sessionType: "Full Game Sim",
                onSendToWatch: {
                    handleSendToWatch()
                }
            )
        }
        .onAppear {
            if sessionManager.isSessionActive {
                sessionManager.setupWatchConnectivity()
                sessionManager.sendSessionStateToWatch()
            }
        }
    }

    // MARK: - Sticky Header

    private var stickyHeaderView: some View {
        VStack(spacing: Spacing.md) {
            // Round Info
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Round \(sessionManager.currentRoundNumber)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.textPrimary)

                    Text(sessionManager.currentRoundNumber % 2 == 1 ? "Team 1 attacking" : "Team 2 attacking")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }

                Spacer()

                // Paused Indicator
                if sessionManager.isPaused {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "pause.circle.fill")
                            .foregroundColor(AppTheme.warning)
                        Text("Paused")
                            .font(.caption)
                            .foregroundColor(AppTheme.warning)
                    }
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(AppTheme.warning.opacity(0.1))
                    .cornerRadius(AppTheme.cornerRadiusSmall)
                }
            }

            // A-Line Status
            if let round = sessionManager.currentRound, sessionManager.currentRoundNumber > 1 {
                if round.hasALine {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.yellow)
                        Text("A-Line Active!")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        if let phase = round.gamePhaseWhenALineAwarded {
                            Text("(earned in \(phase.rawValue.capitalized))")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.yellow.opacity(0.2))
                    .cornerRadius(AppTheme.cornerRadiusSmall)
                } else {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "ruler")
                            .foregroundColor(.gray)
                        Text("Attacking from Baseline")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(AppTheme.cardBackground)
                    .cornerRadius(AppTheme.cornerRadiusSmall)
                }
            }

            // Team Status
            if let session = sessionManager.currentSession {
                HStack(spacing: Spacing.lg) {
                    // Team 1
                    VStack(spacing: Spacing.xs) {
                        Text("Team 1")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                        Text("\(session.team1BaselineKubbs) baseline")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                        if session.team1UnclearedKubbs > 0 {
                            Text("\(session.team1UnclearedKubbs) uncleared")
                                .font(.caption2)
                                .foregroundColor(AppTheme.warning)
                        }
                    }

                    // Team 2
                    VStack(spacing: Spacing.xs) {
                        Text("Team 2")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                        Text("\(session.team2BaselineKubbs) baseline")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                        if session.team2UnclearedKubbs > 0 {
                            Text("\(session.team2UnclearedKubbs) uncleared")
                                .font(.caption2)
                                .foregroundColor(AppTheme.warning)
                        }
                    }
                }
                .padding(Spacing.md)
                .frame(maxWidth: .infinity)
                .background(AppTheme.cardBackground)
                .cornerRadius(AppTheme.cornerRadiusSmall)
            }
        }
        .padding(Spacing.md)
        .background(AppTheme.surface)
        .cornerRadius(AppTheme.cornerRadiusMedium)
        .shadow(color: AppTheme.shadowMedium, radius: 4, y: 2)
    }

    // MARK: - Phase Content

    @ViewBuilder
    private var phaseContentView: some View {
        if let round = sessionManager.currentRound {
            switch sessionManager.currentPhase {
            case .inkast:
                inkastPhaseView(round: round)
            case .attacking:
                attackingPhaseView(round: round)
            case .roundComplete:
                VStack(spacing: Spacing.md) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(AppTheme.success)
                    Text("Round Complete")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.textPrimary)
                }
                .padding(Spacing.xl)
                .frame(maxWidth: .infinity)
                .background(AppTheme.cardBackground)
                .cornerRadius(AppTheme.cornerRadiusMedium)
            }
        } else {
            Text("No active round")
                .foregroundColor(AppTheme.textSecondary)
        }
    }

    // MARK: - Inkast Phase View

    private func inkastPhaseView(round: FullGameSimRoundStruct) -> some View {
        VStack(spacing: Spacing.lg) {
            // Title
            VStack(spacing: Spacing.sm) {
                Image(systemName: "figure.throw")
                    .font(.system(size: 40))
                    .foregroundColor(AppTheme.inkastBlast)

                Text("Inkast Phase")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.textPrimary)
            }

            if round.inkastData.inkastKubbs > 0 {
                Text("Throw \(round.inkastData.inkastKubbs) kubbs past the midline")
                    .font(.body)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)

                Button("Record Results") {
                    showingInkastRecording = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            } else {
                Text("No kubbs to inkast this round")
                    .font(.body)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)

                Button("Continue to Blast Phase") {
                    sessionManager.completeInkastPhase()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadiusMedium)
        .shadow(color: AppTheme.shadowMedium, radius: 4, y: 2)
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

    // MARK: - Attacking Phase View

    private func attackingPhaseView(round: FullGameSimRoundStruct) -> some View {
        VStack(spacing: Spacing.lg) {
            // Pitch Visual
            if let session = sessionManager.currentSession {
                FullGamePitchVisualView(
                    roundData: round,
                    sessionData: session,
                    skin: skinManager.selectedKubbSkin
                )
            }

            // Baton Visual
            BatonRow(
                skin: skinManager.selectedBatonSkin,
                currentBaton: getCurrentBatonForAttackingPhase(round),
                totalBatons: getBatonLimitForRound(round.roundNumber)
            )
        }
        .padding(Spacing.md)
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadiusMedium)
        .shadow(color: AppTheme.shadowMedium, radius: 4, y: 2)
        .sheet(isPresented: $showingHitRecording) {
            if let session = sessionManager.currentSession {
                FullGameHitRecordingView(
                    roundData: round,
                    sessionData: session,
                    skin: skinManager.selectedKubbSkin,
                    onConfirm: { fieldKubbsHit, baselineKubbsHit, kingHit in
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
        case 1: return 2
        case 2: return 4
        default: return 6
        }
    }

    private func getCurrentBatonForAttackingPhase(_ round: FullGameSimRoundStruct) -> Int {
        if round.roundNumber == 1 {
            return round.eightMeterData.batonsUsed + 1
        }
        let totalBatonsUsed = round.blastData.batonsUsed + round.eightMeterData.batonsUsed
        return totalBatonsUsed + 1
    }

    private func hasFieldKubbsRemaining(_ round: FullGameSimRoundStruct) -> Bool {
        return round.inkastData.totalKubbsInBounds - round.blastData.kubbsClearedFirstThrow > 0
    }

    // MARK: - Throw Controls Card

    private var throwControlsCard: some View {
        Group {
            if sessionManager.currentPhase == .attacking, let round = sessionManager.currentRound {
                VStack(spacing: Spacing.md) {
                    Text("Baton \(getCurrentBatonForAttackingPhase(round))")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.textPrimary)

                    // Hit/Miss Buttons
                    HStack(spacing: Spacing.md) {
                        // Miss Button
                        Button(action: {
                            if hasFieldKubbsRemaining(round) {
                                sessionManager.addBlastBatonThrow(isHit: false)
                            } else {
                                sessionManager.addEightMeterBatonThrow(isHit: false)
                            }
                        }) {
                            HStack(spacing: Spacing.sm) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.white)

                                Text("MISS")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 70)
                            .background(AppTheme.error)
                            .cornerRadius(AppTheme.cornerRadiusMedium)
                            .shadow(color: AppTheme.shadowMedium, radius: 4, y: 2)
                        }

                        // Hit Button
                        Button(action: {
                            showingHitRecording = true
                        }) {
                            HStack(spacing: Spacing.sm) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.white)

                                Text("HIT")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 70)
                            .background(AppTheme.success)
                            .cornerRadius(AppTheme.cornerRadiusMedium)
                            .shadow(color: AppTheme.shadowMedium, radius: 4, y: 2)
                        }
                    }

                    // Undo Button
                    if !round.blastData.batonThrows.isEmpty || !round.eightMeterData.batonThrows.isEmpty {
                        Button(action: {
                            sessionManager.undoLastThrow()
                        }) {
                            HStack(spacing: Spacing.sm) {
                                Image(systemName: "arrow.uturn.backward.circle.fill")
                                    .font(.system(size: 20))

                                Text("Undo Last Throw")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(AppTheme.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(AppTheme.primary.opacity(0.1))
                            .cornerRadius(AppTheme.cornerRadiusSmall)
                        }
                    }
                }
                .padding(Spacing.md)
                .background(AppTheme.cardBackground)
                .cornerRadius(AppTheme.cornerRadiusMedium)
                .shadow(color: AppTheme.shadowMedium, radius: 4, y: 2)
            }
        }
    }

    private func handleSendToWatch() {
        // Create session state
        let sessionState = WatchSessionState(
            sessionType: "Full Game Sim",
            isActive: true,
            currentRound: sessionManager.currentRoundNumber,
            totalRounds: 3, // Full Game Sim is 3 rounds
            currentPhase: sessionManager.currentPhase.rawValue,
            isWatchMode: false,
            targetBatons: nil,
            currentBatons: nil,
            hasALine: sessionManager.hasALine,
            currentAttackingTeam: sessionManager.currentRoundIsUserAttacking ? "User" : "Opponent"
        )

        // Send to watch
        WatchConnectivityManager.shared.sendSessionToWatch(
            sessionType: "Full Game Sim",
            sessionState: sessionState
        )
    }
}

// MARK: - Game Phase Info Card Component

struct GamePhaseInfoCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)
            }

            // Content
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)

                Text(description)
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(Spacing.md)
        .background(AppTheme.surface)
        .cornerRadius(AppTheme.cornerRadiusMedium)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    FullGameSimViewRedesigned(
        persistenceController: PersistenceController.preview,
        cloudKitManager: CloudKitManager.shared
    )
}
