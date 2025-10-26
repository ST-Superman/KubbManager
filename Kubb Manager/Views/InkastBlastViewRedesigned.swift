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
        case .early:
            return AppTheme.phaseEarly
        case .mid:
            return AppTheme.phaseMid
        case .end:
            return AppTheme.phaseEnd
        case .all:
            return AppTheme.primary
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
    @State private var showingSendToWatchSheet = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .top) {
            AppTheme.surface.ignoresSafeArea()

            VStack(spacing: 0) {
                // Sticky Header
                if let round = sessionManager.currentRound {
                    stickyHeaderCard(round: round)
                }

                // Scrollable Content
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: Spacing.sectionSpacing) {
                        // Round Phase Content
                        roundPhaseContent
                    }
                    .padding(Spacing.screenPadding)
                }
            }
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
                HStack(spacing: 16) {
                    WatchIconButton {
                        showingSendToWatchSheet = true
                    }

                    Button(sessionManager.isPaused ? "Resume" : "Pause") {
                        if sessionManager.isPaused {
                            sessionManager.resumeSession()
                        } else {
                            sessionManager.pauseSession()
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingSendToWatchSheet) {
            SendToWatchSheet(
                isPresented: $showingSendToWatchSheet,
                sessionType: "Inkast & Blast",
                onSendToWatch: {
                    handleSendToWatch()
                }
            )
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

    // MARK: - Sticky Header Card

    private func stickyHeaderCard(round: InkastBlastRoundData) -> some View {
        VStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.md) {
                // Round and Phase Info
                VStack(alignment: .leading, spacing: 2) {
                    Text("Round \(sessionManager.currentRoundNumber)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.textPrimary)

                    Text(phaseDisplayName)
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }

                Spacer()

                // Stats Compact
                HStack(spacing: Spacing.md) {
                    StatItemCompact(label: "Kubbs", value: "\(round.inkastKubbs)", color: AppTheme.inkastBlast)
                    StatItemCompact(label: "Target", value: "\(round.targetBatons)", color: AppTheme.primary)
                    StatItemCompact(label: "Used", value: "\(round.batonsUsed)", color: round.batonsUsed <= round.targetBatons ? AppTheme.success : AppTheme.error)
                }
            }

            // Phase indicator bar
            if sessionManager.roundPhase == .blasting {
                ProgressView(value: Double(round.batonsUsed), total: Double(max(round.targetBatons, round.batonsUsed)))
                    .tint(round.batonsUsed <= round.targetBatons ? AppTheme.success : AppTheme.error)
                    .frame(height: 4)
            }
        }
        .padding(Spacing.md)
        .background(
            AppTheme.cardBackground
                .shadow(color: AppTheme.shadowStrong, radius: 8, y: 4)
        )
    }

    private var phaseDisplayName: String {
        switch sessionManager.roundPhase {
        case .inkast:
            return "Inkast Phase"
        case .blasting:
            return "Blasting Phase"
        case .roundComplete:
            return "Complete"
        case .firstAttemptResults:
            return "First Attempt"
        case .secondAttempt:
            return "Second Attempt"
        case .secondAttemptResults:
            return "Second Attempt"
        case .neighborCheck:
            return "Neighbor Check"
        }
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
        case .firstAttemptResults, .secondAttempt, .secondAttemptResults, .neighborCheck:
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
            if let round = sessionManager.currentRound {
                // Throw History Card
                InkastThrowHistoryCard(batonThrows: round.batonThrows)

                // Baton Visual
                BatonRow(
                    skin: skinManager.selectedBatonSkin,
                    currentBaton: round.batonsUsed + 1,
                    totalBatons: 6
                )

                // Hit/Miss Buttons
                VStack(spacing: Spacing.md) {
                    HStack(spacing: Spacing.md) {
                        // Miss Button
                        Button(action: {
                            sessionManager.addBatonThrow(isHit: false)
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
                    if !round.batonThrows.isEmpty {
                        Button(action: {
                            sessionManager.undoLastBatonThrow()
                        }) {
                            HStack(spacing: Spacing.sm) {
                                Image(systemName: "arrow.uturn.backward.circle.fill")
                                    .font(.system(size: 20))

                                Text("Undo Last Throw")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(AppTheme.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(AppTheme.primary.opacity(0.1))
                            .cornerRadius(AppTheme.cornerRadiusMedium)
                        }
                    }
                }
            }
        }
        .padding(Spacing.md)
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
                        .foregroundColor(AppTheme.textPrimary)

                    Text("Target was \(round.targetBatons) batons")
                        .font(.body)
                        .foregroundColor(AppTheme.textSecondary)

                    if round.performanceVsTarget > 0 {
                        Text("+\(round.performanceVsTarget) under target! 🎉")
                            .font(.body)
                            .foregroundColor(AppTheme.success)
                    } else if round.performanceVsTarget < 0 {
                        Text("\(round.performanceVsTarget) over target")
                            .font(.body)
                            .foregroundColor(AppTheme.error)
                    } else {
                        Text("Exactly on target! 🎯")
                            .font(.body)
                            .foregroundColor(AppTheme.primary)
                    }
                }

                HStack(spacing: Spacing.md) {
                    Button("Next Round") {
                        sessionManager.startNextRound()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(AppTheme.primary)
                    .cornerRadius(AppTheme.cornerRadiusMedium)
                    .shadow(color: AppTheme.shadowMedium, radius: 4, y: 2)

                    Button("End Session") {
                        sessionManager.endSession()
                        showingSessionSummary = true
                    }
                    .font(.headline)
                    .foregroundColor(AppTheme.warning)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(AppTheme.warning.opacity(0.1))
                    .cornerRadius(AppTheme.cornerRadiusMedium)
                }
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadiusMedium)
        .shadow(color: AppTheme.shadowMedium, radius: 4, y: 2)
    }

    private func handleSendToWatch() {
        // Create session state
        let sessionState = WatchSessionState(
            sessionType: "Inkast & Blast",
            isActive: true,
            currentRound: sessionManager.currentRoundNumber,
            totalRounds: nil,
            currentPhase: sessionManager.currentPhase.rawValue,
            isWatchMode: false,
            targetBatons: sessionManager.targetBatons,
            currentBatons: nil,
            hasALine: nil,
            currentAttackingTeam: nil
        )

        // Send to watch
        WatchConnectivityManager.shared.sendSessionToWatch(
            sessionType: "Inkast & Blast",
            sessionState: sessionState
        )
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

struct StatItemCompact: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(color)

            Text(label)
                .font(.system(size: 10))
                .foregroundColor(AppTheme.textSecondary)
        }
    }
}

private struct InkastThrowHistoryCard: View {
    let batonThrows: [InkastBatonThrowData]

    var recentThrows: [(isHit: Bool, kubbsHit: Int)] {
        batonThrows.map { (isHit: $0.isHit, kubbsHit: $0.kubbsHit) }
    }

    var body: some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                Text("This Round")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.textSecondary)

                Spacer()

                if !recentThrows.isEmpty {
                    Text("\(recentThrows.filter { $0.isHit }.count)/\(recentThrows.count)")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }

            HStack(spacing: Spacing.xs) {
                ForEach(0..<6, id: \.self) { index in
                    if index < recentThrows.count {
                        let throwData = recentThrows[index]
                        ZStack {
                            Circle()
                                .fill(throwData.isHit ? AppTheme.success : AppTheme.error)
                                .frame(width: 32, height: 32)

                            if throwData.isHit && throwData.kubbsHit > 1 {
                                ZStack {
                                    Circle()
                                        .fill(.white)
                                        .frame(width: 18, height: 18)

                                    Text("\(throwData.kubbsHit)")
                                        .font(.system(size: 11, weight: .black))
                                        .foregroundColor(AppTheme.success)
                                }
                            } else {
                                Image(systemName: throwData.isHit ? "checkmark" : "xmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    } else {
                        Circle()
                            .fill(AppTheme.textSecondary.opacity(0.15))
                            .frame(width: 32, height: 32)
                    }
                }
            }
        }
        .padding(Spacing.md)
        .background(AppTheme.cardBackground.opacity(0.5))
        .cornerRadius(AppTheme.cornerRadiusMedium)
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
