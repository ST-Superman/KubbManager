//
//  PracticeViewRedesigned.swift
//  Kubb Manager
//
//  Redesigned practice interface with improved UX and visual hierarchy
//

import SwiftUI

// MARK: - Main Practice View (Redesigned)

struct PracticeViewRedesigned: View {
    @EnvironmentObject private var sessionManager: SessionManager
    @Environment(\.dismiss) private var dismiss

    // Alerts and modals
    @State private var showingEndSessionAlert = false
    @State private var showingPauseSessionAlert = false
    @State private var showingResetRoundAlert = false
    @State private var showingRoundCompleteModal = false
    @State private var showingTargetReachedModal = false
    @State private var showingSendToWatchSheet = false

    // Tracking state
    @State private var lastCompletedRound: Round?
    @State private var lastTargetReachedBatons = 0
    @State private var hasShownTargetReachedAlert = false

    // Haptic feedback
    private let hapticSuccess = UINotificationFeedbackGenerator()
    private let hapticError = UINotificationFeedbackGenerator()
    private let hapticImpact = UIImpactFeedbackGenerator(style: .heavy)

    var body: some View {
        mainContent
            .alert("Pause Session", isPresented: $showingPauseSessionAlert) {
                pauseSessionAlertButtons
            } message: {
                pauseSessionAlertMessage
            }
            .alert("End Session", isPresented: $showingEndSessionAlert) {
                endSessionAlertButtons
            } message: {
                endSessionAlertMessage
            }
            .alert("Reset Round", isPresented: $showingResetRoundAlert) {
                resetRoundAlertButtons
            } message: {
                resetRoundAlertMessage
            }
            .sheet(isPresented: $showingSendToWatchSheet) {
                SendToWatchSheet(
                    isPresented: $showingSendToWatchSheet,
                    sessionType: "8M Training",
                    onSendToWatch: {
                        handleSendToWatch()
                    }
                )
            }
            .onChange(of: sessionManager.isTargetReached) { _, isReached in
                handleTargetReached(isReached)
            }
            .onChange(of: sessionManager.currentRound) { _, newCurrentRound in
                handleRoundChange(newCurrentRound)
            }
    }

    // MARK: - Computed Properties for Body

    private var mainContent: some View {
        NavigationView {
            practiceContent
                .navigationTitle("Practice Session")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    toolbarContent
                }
        }
    }

    private var practiceContent: some View {
        ZStack(alignment: .top) {
            AppTheme.surface
                .ignoresSafeArea()

            VStack(spacing: 0) {
                StickyProgressHeader()
                    .environmentObject(sessionManager)

                scrollableContent
            }

            modalOverlays
        }
    }

    private var scrollableContent: some View {
        ScrollView {
            VStack(spacing: Spacing.sectionSpacing) {
                CurrentRoundCard(lastCompletedRound: lastCompletedRound)
                    .padding(.horizontal, Spacing.screenPadding)
                    .padding(.top, Spacing.md)

                ThrowHistoryCard()
                    .padding(.horizontal, Spacing.screenPadding)

                BatonControlsRedesigned(
                    onHit: { recordBatonResult(isHit: true) },
                    onMiss: { recordBatonResult(isHit: false) },
                    onUndo: { undoLastThrow() }
                )
                .padding(.horizontal, Spacing.screenPadding)

                SessionActionsCard(
                    onResetRound: { showingResetRoundAlert = true }
                )
                .padding(.horizontal, Spacing.screenPadding)
                .padding(.bottom, Spacing.screenPadding)

                watchControlPanel
            }
        }
    }

    private var watchControlPanel: some View {
        WatchSessionControlPanel(
            sessionType: "8M Training",
            onStartWatchInput: {
                sessionManager.requestWatchBatonInput()
            },
            onSendSessionState: {
                sessionManager.sendSessionStateToWatch()
            }
        )
        .padding(.horizontal, Spacing.screenPadding)
        .padding(.bottom, Spacing.screenPadding)
    }

    @ViewBuilder
    private var modalOverlays: some View {
        if showingRoundCompleteModal {
            RoundCompleteModalRedesigned(
                isPresented: $showingRoundCompleteModal,
                onStartNextRound: {
                    Task {
                        await sessionManager.startNextRound()
                        showingRoundCompleteModal = false
                    }
                }
            )
        }

        if showingTargetReachedModal {
            TargetReachedModalRedesigned(
                isPresented: $showingTargetReachedModal,
                target: sessionManager.target,
                onContinuePractice: {
                    showingTargetReachedModal = false
                    hasShownTargetReachedAlert = true
                },
                onEndSession: {
                    Task {
                        await sessionManager.completeSession()
                        dismiss()
                    }
                }
            )
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("Pause") {
                showingPauseSessionAlert = true
            }
            .foregroundColor(AppTheme.warning)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            HStack(spacing: 16) {
                WatchIconButton {
                    showingSendToWatchSheet = true
                }

                Button("End") {
                    showingEndSessionAlert = true
                }
                .foregroundColor(AppTheme.error)
            }
        }
    }

    // Alert content
    @ViewBuilder
    private var pauseSessionAlertButtons: some View {
        Button("Cancel", role: .cancel) { }
        Button("Pause") {
            Task {
                await sessionManager.pauseSession()
                dismiss()
            }
        }
    }

    private var pauseSessionAlertMessage: some View {
        Text("Pause this practice session? You can resume it later from the main menu.")
    }

    @ViewBuilder
    private var endSessionAlertButtons: some View {
        Button("Cancel", role: .cancel) { }
        Button("End Session", role: .destructive) {
            Task {
                await sessionManager.completeSession()
                dismiss()
            }
        }
    }

    private var endSessionAlertMessage: some View {
        Text("Are you sure you want to end this practice session? Your progress will be saved.")
    }

    @ViewBuilder
    private var resetRoundAlertButtons: some View {
        Button("Cancel", role: .cancel) { }
        Button("Reset Round", role: .destructive) {
            Task {
                await sessionManager.resetCurrentRound()
            }
        }
    }

    private var resetRoundAlertMessage: some View {
        Text("Are you sure you want to reset the current round? This will clear all progress for this round.")
    }

    // MARK: - Event Handlers

    private func handleTargetReached(_ isReached: Bool) {
        if isReached && !hasShownTargetReachedAlert && sessionManager.totalBatons > lastTargetReachedBatons {
            hapticSuccess.notificationOccurred(.success)
            showingTargetReachedModal = true
            lastTargetReachedBatons = sessionManager.totalBatons
        }
    }

    private func handleRoundChange(_ newCurrentRound: Round?) {
        if newCurrentRound == nil,
           let session = sessionManager.currentSession,
           !session.rounds.isEmpty,
           let lastRound = session.rounds.last,
           lastRound.isComplete && lastRound != lastCompletedRound {
            lastCompletedRound = lastRound
            showingRoundCompleteModal = true
        }
    }

    // MARK: - Helper Methods

    private func recordBatonResult(isHit: Bool) {
        hapticImpact.impactOccurred()

        if isHit {
            hapticSuccess.notificationOccurred(.success)
        } else {
            hapticError.notificationOccurred(.error)
        }

        Task {
            await sessionManager.addBatonResult(isHit: isHit)
        }
    }

    private func undoLastThrow() {
        hapticImpact.impactOccurred()

        Task {
            await sessionManager.undoLastBatonThrow()
        }
    }

    private func handleSendToWatch() {
        // Create session state
        let sessionState = WatchSessionState(
            sessionType: "8M Training",
            isActive: true,
            currentRound: sessionManager.currentRound?.roundNumber ?? 1,
            totalRounds: nil,
            currentPhase: nil,
            isWatchMode: false,
            targetBatons: sessionManager.target,
            currentBatons: sessionManager.totalBatons,
            hasALine: nil,
            currentAttackingTeam: nil
        )

        // Send to watch
        WatchConnectivityManager.shared.sendSessionToWatch(
            sessionType: "8M Training",
            sessionState: sessionState
        )

        // Immediately request input on watch so user can start recording
        sessionManager.requestWatchBatonInput()
    }
}

// MARK: - Sticky Progress Header

struct StickyProgressHeader: View {
    @EnvironmentObject private var sessionManager: SessionManager

    var body: some View {
        VStack(spacing: Spacing.xs) {
            // Top bar with round info
            HStack {
                // Round indicator
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                        .foregroundColor(AppTheme.primary)

                    Text("Round \(currentRoundNumber)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.textPrimary)
                }

                Spacer()

                // Quick stats
                HStack(spacing: Spacing.md) {
                    // Accuracy
                    HStack(spacing: 4) {
                        Image(systemName: "target")
                            .font(.caption2)
                            .foregroundColor(accuracyColor)
                        Text(String(format: "%.0f%%", sessionManager.accuracy * 100))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(accuracyColor)
                    }

                    // Batons
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.caption2)
                            .foregroundColor(AppTheme.warning)
                        Text("\(sessionManager.totalBatons)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(AppTheme.textPrimary)
                    }
                }
            }
            .padding(.horizontal, Spacing.screenPadding)
            .padding(.top, Spacing.sm)

            // Progress bar
            VStack(spacing: Spacing.xs) {
                HStack {
                    Text("\(sessionManager.totalBatons) / \(sessionManager.target) batons")
                        .font(.caption2)
                        .foregroundColor(AppTheme.textSecondary)

                    Spacer()

                    Text(String(format: "%.0f%%", sessionManager.progressPercentage * 100))
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(progressColor)
                }

                ProgressView(value: sessionManager.progressPercentage)
                    .progressViewStyle(LinearProgressViewStyle(tint: progressColor))
                    .scaleEffect(x: 1, y: 1.5, anchor: .center)
            }
            .padding(.horizontal, Spacing.screenPadding)
            .padding(.bottom, Spacing.sm)
        }
        .background(
            AppTheme.cardBackground
                .shadow(color: AppTheme.shadowLight, radius: 2, y: 2)
        )
    }

    private var currentRoundNumber: Int {
        if let currentRound = sessionManager.currentRound {
            return currentRound.roundNumber
        } else if let lastRound = sessionManager.currentSession?.rounds.last {
            return lastRound.roundNumber
        }
        return 1
    }

    private var progressColor: Color {
        let percentage = sessionManager.progressPercentage
        if percentage >= 1.0 {
            return AppTheme.success
        } else if percentage >= 0.7 {
            return AppTheme.primary
        } else if percentage >= 0.4 {
            return AppTheme.warning
        } else {
            return AppTheme.error
        }
    }

    private var accuracyColor: Color {
        let accuracy = sessionManager.accuracy
        if accuracy >= 0.7 {
            return AppTheme.success
        } else if accuracy >= 0.5 {
            return AppTheme.warning
        } else {
            return AppTheme.error
        }
    }
}

// MARK: - Current Round Card

struct CurrentRoundCard: View {
    @EnvironmentObject private var sessionManager: SessionManager
    @StateObject private var skinManager = SkinManager.shared
    let lastCompletedRound: Round?

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Section header
            HStack {
                Image(systemName: "square.grid.3x2")
                    .foregroundColor(AppTheme.primary)
                Text("Current Round")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()
            }

            // Kubb grid
            VStack(spacing: Spacing.md) {
                // 5 baseline kubbs
                HStack(spacing: Spacing.sm) {
                    ForEach(0..<5, id: \.self) { index in
                        KubbView(
                            number: index + 1,
                            isKnockedDown: getKubbState(at: index),
                            skin: skinManager.selectedKubbSkin
                        )
                    }
                }

                // King kubb (if baseline is clear)
                if let displayRound = getDisplayRound(), displayRound.hits >= 5 {
                    KingKubbView(
                        isKnockedDown: displayRound.kingThrowsCount > 0 && displayRound.kingHits > 0,
                        skin: skinManager.selectedKingSkin
                    )
                }
            }

            // Round stats
            if let displayRound = getDisplayRound() {
                HStack(spacing: Spacing.xl) {
                    // Hits
                    VStack(spacing: Spacing.xs) {
                        Text("\(displayRound.hits)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.success)
                        Text("Hits")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }

                    // Misses
                    VStack(spacing: Spacing.xs) {
                        Text("\(displayRound.misses)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.error)
                        Text("Misses")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }

                    // Total throws
                    VStack(spacing: Spacing.xs) {
                        Text("\(displayRound.totalBatonThrows)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.primary)
                        Text("Throws")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }

                // Badges
                HStack(spacing: Spacing.sm) {
                    if displayRound.hasBaselineClear {
                        HStack(spacing: 4) {
                            Image(systemName: "crown.fill")
                                .font(.caption2)
                            Text("Baseline Clear!")
                                .font(.caption2)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, 4)
                        .background(AppTheme.warning)
                        .cornerRadius(AppTheme.cornerRadiusSmall)
                    }

                    if displayRound.kingThrowsCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "crown")
                                .font(.caption2)
                            Text("King Throws: \(displayRound.kingThrowsCount)")
                                .font(.caption2)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, 4)
                        .background(AppTheme.accent)
                        .cornerRadius(AppTheme.cornerRadiusSmall)
                    }
                }
            }
        }
        .padding(Spacing.md)
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadiusMedium)
        .shadow(color: AppTheme.shadowLight, radius: 2, y: 1)
    }

    private func getDisplayRound() -> Round? {
        return sessionManager.currentRound ?? lastCompletedRound
    }

    private func getKubbState(at index: Int) -> Bool {
        return getDisplayRound()?.kubbState(at: index) ?? false
    }
}

// MARK: - Throw History Card (NEW!)

struct ThrowHistoryCard: View {
    @EnvironmentObject private var sessionManager: SessionManager

    var body: some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(AppTheme.primary)
                Text("Recent Throws")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                if !recentThrows.isEmpty {
                    Text("\(recentThrows.filter { $0 }.count)/\(recentThrows.count)")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }

            HStack(spacing: Spacing.xs) {
                ForEach(0..<6, id: \.self) { index in
                    if index < recentThrows.count {
                        ThrowIndicator(
                            isHit: recentThrows[index],
                            isLatest: index == recentThrows.count - 1
                        )
                    } else {
                        Circle()
                            .fill(AppTheme.textSecondary.opacity(0.15))
                            .frame(width: 32, height: 32)
                    }
                }
            }
        }
        .padding(Spacing.md)
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadiusMedium)
        .shadow(color: AppTheme.shadowLight, radius: 2, y: 1)
    }

    private var recentThrows: [Bool] {
        guard let currentRound = sessionManager.currentRound else { return [] }
        return currentRound.batonThrows.map { $0.isHit }
    }
}

struct ThrowIndicator: View {
    let isHit: Bool
    let isLatest: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(isHit ? AppTheme.success : AppTheme.error)
                .frame(width: 32, height: 32)

            Image(systemName: isHit ? "checkmark" : "xmark")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .overlay(
            Circle()
                .stroke(isLatest ? AppTheme.primary : Color.clear, lineWidth: 2)
        )
        .scaleEffect(isLatest ? 1.1 : 1.0)
        .animation(.spring(response: 0.3), value: isLatest)
    }
}

// MARK: - Baton Controls (Redesigned)

struct BatonControlsRedesigned: View {
    @EnvironmentObject private var sessionManager: SessionManager
    let onHit: () -> Void
    let onMiss: () -> Void
    let onUndo: () -> Void

    private var isRoundComplete: Bool {
        return sessionManager.currentRound?.isRoundComplete ?? true
    }

    private var canUndo: Bool {
        return sessionManager.currentRound?.batonThrows.isEmpty == false
    }

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Instruction text
            Text(isRoundComplete ? "Round complete - tap 'Start Next Round'" : "Tap the result of your baton throw")
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)

            // Large HIT/MISS buttons
            HStack(spacing: Spacing.md) {
                // MISS button
                Button(action: onMiss) {
                    VStack(spacing: Spacing.sm) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white)

                        Text("MISS")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 140)
                    .background(isRoundComplete ? AppTheme.textTertiary : AppTheme.error)
                    .cornerRadius(AppTheme.cornerRadiusMedium)
                    .shadow(color: isRoundComplete ? AppTheme.shadowLight : AppTheme.error.opacity(0.3), radius: 4, y: 2)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isRoundComplete)

                // HIT button
                Button(action: onHit) {
                    VStack(spacing: Spacing.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white)

                        Text("HIT")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 140)
                    .background(isRoundComplete ? AppTheme.textTertiary : AppTheme.success)
                    .cornerRadius(AppTheme.cornerRadiusMedium)
                    .shadow(color: isRoundComplete ? AppTheme.shadowLight : AppTheme.success.opacity(0.3), radius: 4, y: 2)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isRoundComplete)
            }

            // Undo button - NEW!
            Button(action: onUndo) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.subheadline)
                    Text("Undo Last Throw")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(canUndo ? AppTheme.warning : AppTheme.textTertiary)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(canUndo ? AppTheme.warning.opacity(0.1) : AppTheme.textTertiary.opacity(0.1))
                .cornerRadius(AppTheme.cornerRadiusSmall)
            }
            .disabled(!canUndo)
        }
    }
}

// MARK: - Session Actions Card

struct SessionActionsCard: View {
    let onResetRound: () -> Void

    var body: some View {
        VStack(spacing: Spacing.sm) {
            Button(action: onResetRound) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.subheadline)
                    Text("Reset Current Round")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(AppTheme.warning)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
                .background(AppTheme.warning.opacity(0.1))
                .cornerRadius(AppTheme.cornerRadiusSmall)
            }

            Text("Tap to reset if you need to start this round over")
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(Spacing.md)
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadiusMedium)
        .shadow(color: AppTheme.shadowLight, radius: 2, y: 1)
    }
}

// MARK: - Round Complete Modal (Redesigned)

struct RoundCompleteModalRedesigned: View {
    @Binding var isPresented: Bool
    let onStartNextRound: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { }

            VStack(spacing: Spacing.lg) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(AppTheme.success)

                Text("Round Complete!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.textPrimary)

                Text("Please stand any knocked down kubbs back up and retrieve your batons before starting the next round.")
                    .font(.body)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)

                ActionButton.primary("Start Next Round", icon: "arrow.right") {
                    onStartNextRound()
                }
            }
            .padding(Spacing.xl)
            .background(AppTheme.cardBackground)
            .cornerRadius(AppTheme.cornerRadiusLarge)
            .shadow(color: AppTheme.shadowStrong, radius: 20)
            .padding(.horizontal, 40)
        }
    }
}

// MARK: - Target Reached Modal (Redesigned)

struct TargetReachedModalRedesigned: View {
    @Binding var isPresented: Bool
    let target: Int
    let onContinuePractice: () -> Void
    let onEndSession: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { }

            VStack(spacing: Spacing.lg) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 60))
                    .foregroundColor(AppTheme.warning)

                Text("Target Reached!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.textPrimary)

                Text("Congratulations! You've reached your target of \(target) batons! 🎉\n\nWould you like to continue practicing or end your session?")
                    .font(.body)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)

                VStack(spacing: Spacing.sm) {
                    ActionButton.primary("End Session", icon: "checkmark") {
                        onEndSession()
                    }

                    ActionButton.secondary("Continue Practice", icon: "arrow.forward") {
                        onContinuePractice()
                    }
                }
            }
            .padding(Spacing.xl)
            .background(AppTheme.cardBackground)
            .cornerRadius(AppTheme.cornerRadiusLarge)
            .shadow(color: AppTheme.shadowStrong, radius: 20)
            .padding(.horizontal, 40)
        }
    }
}

#Preview {
    PracticeViewRedesigned()
        .environmentObject(SessionManager())
}
