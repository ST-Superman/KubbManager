//
//  BaseballKubbViewRedesigned.swift
//  Kubb Manager
//
//  Redesigned Baseball Kubb using NavigationStack pattern and design system
//

import SwiftUI

// MARK: - Main View

struct BaseballKubbViewRedesigned: View {
    @StateObject private var sessionManager = BaseballKubbSessionManager()
    @State private var showingTutorial = false
    @State private var navigateToGame = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            BaseballKubbOverviewRoot(
                sessionManager: sessionManager,
                navigateToGame: $navigateToGame
            )
            .navigationTitle("Baseball Kubb")
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
            .navigationDestination(isPresented: $navigateToGame) {
                BaseballKubbActiveGameView(sessionManager: sessionManager)
            }
            .sheet(isPresented: $showingTutorial) {
                BaseballKubbTutorialView()
            }
        }
    }
}

// MARK: - Overview Root

struct BaseballKubbOverviewRoot: View {
    @ObservedObject var sessionManager: BaseballKubbSessionManager
    @Binding var navigateToGame: Bool
    @State private var awayTeam = ""
    @State private var homeTeam = ""
    @State private var selectedUserTeam: UserTeam? = nil
    @State private var showingAbandonConfirmation = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: Spacing.sectionSpacing) {
                // Check if there's an active or incomplete session
                if sessionManager.currentSession != nil || sessionManager.incompleteSession != nil {
                    // Navigate to active game
                    Text("")
                        .onAppear {
                            navigateToGame = true
                        }
                } else {
                    // Show start view
                    heroSection
                    incompleteGameSection
                    teamSetupSection
                    if !awayTeam.isEmpty && !homeTeam.isEmpty && awayTeam != homeTeam {
                        teamSelectionSection
                    }
                    startButtonSection
                }
            }
            .padding(Spacing.screenPadding)
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: Spacing.md) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(AppTheme.baseballKubb.opacity(0.15))
                    .frame(width: 140, height: 140)

                Image("baseball_kubb")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
            }

            // Title & Description
            VStack(spacing: Spacing.xs) {
                Text("Baseball Kubb")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.textPrimary)

                Text("Baseball-style training with innings and scoring")
                    .font(.subheadline)
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

    // MARK: - Incomplete Game Section

    @ViewBuilder
    private var incompleteGameSection: some View {
        if let incompleteSession = sessionManager.incompleteSession {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionHeader.simple("Game in Progress")

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack {
                        Text("\(incompleteSession.awayTeam) vs \(incompleteSession.homeTeam)")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                    }

                    Text("Inning \(incompleteSession.currentInning) - \(incompleteSession.isTop ? "Top" : "Bottom")")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)

                    Text("Score: \(incompleteSession.awayScore) - \(incompleteSession.homeScore)")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)

                    Text("Last played: \(incompleteSession.modifiedAt, style: .relative) ago")
                        .font(.caption)
                        .foregroundColor(AppTheme.textTertiary)
                }
                .padding(Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.warning.opacity(0.1))
                .cornerRadius(AppTheme.cornerRadiusMedium)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                        .stroke(AppTheme.warning.opacity(0.3), lineWidth: 2)
                )

                HStack(spacing: Spacing.md) {
                    Button("Resume Game") {
                        sessionManager.resumeIncompleteGame()
                        navigateToGame = true
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(AppTheme.success)
                    .cornerRadius(AppTheme.cornerRadiusMedium)

                    Button("Abandon") {
                        showingAbandonConfirmation = true
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(AppTheme.error)
                    .cornerRadius(AppTheme.cornerRadiusMedium)
                }
            }
            .sheet(isPresented: $showingAbandonConfirmation) {
                if let session = sessionManager.incompleteSession {
                    BaseballKubbAbandonConfirmationView(
                        session: session,
                        sessionManager: sessionManager,
                        showingAbandonConfirmation: $showingAbandonConfirmation
                    )
                }
            }

            // Divider
            Divider()
                .padding(.vertical, Spacing.md)
        }
    }

    // MARK: - Team Setup Section

    private var teamSetupSection: some View {
        VStack(spacing: Spacing.lg) {
            SectionHeader.simple("Team Setup")

            VStack(spacing: Spacing.md) {
                // Away Team Card
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack {
                        Image(systemName: "figure.baseball")
                            .font(.title2)
                            .foregroundColor(AppTheme.baseballKubb)

                        Text("Away Team")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.textPrimary)

                        Spacer()
                    }

                    TextField("Red Sox, Yankees, etc.", text: $awayTeam)
                        .font(.body)
                        .padding(Spacing.md)
                        .background(AppTheme.surface)
                        .cornerRadius(AppTheme.cornerRadiusMedium)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                                .stroke(awayTeam.isEmpty ? Color.gray.opacity(0.2) : AppTheme.baseballKubb.opacity(0.5), lineWidth: 2)
                        )
                }
                .padding(Spacing.md)
                .background(AppTheme.cardBackground)
                .cornerRadius(AppTheme.cornerRadiusMedium)
                .shadow(color: AppTheme.shadowLight, radius: 2, y: 1)

                // VS Badge
                ZStack {
                    Circle()
                        .fill(AppTheme.baseballKubb.opacity(0.1))
                        .frame(width: 60, height: 60)

                    Text("VS")
                        .font(.title2)
                        .fontWeight(.black)
                        .foregroundColor(AppTheme.baseballKubb)
                }
                .padding(.vertical, Spacing.sm)

                // Home Team Card
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack {
                        Image(systemName: "house.fill")
                            .font(.title2)
                            .foregroundColor(AppTheme.baseballKubb)

                        Text("Home Team")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.textPrimary)

                        Spacer()
                    }

                    TextField("Cubs, Dodgers, etc.", text: $homeTeam)
                        .font(.body)
                        .padding(Spacing.md)
                        .background(AppTheme.surface)
                        .cornerRadius(AppTheme.cornerRadiusMedium)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                                .stroke(homeTeam.isEmpty ? Color.gray.opacity(0.2) : AppTheme.baseballKubb.opacity(0.5), lineWidth: 2)
                        )
                        .onSubmit {
                            if canStartGame {
                                startGame()
                            }
                        }
                }
                .padding(Spacing.md)
                .background(AppTheme.cardBackground)
                .cornerRadius(AppTheme.cornerRadiusMedium)
                .shadow(color: AppTheme.shadowLight, radius: 2, y: 1)
            }
        }
    }

    // MARK: - Team Selection Section

    private var teamSelectionSection: some View {
        UserTeamSelectionView(
            selectedTeam: $selectedUserTeam,
            awayTeam: awayTeam,
            homeTeam: homeTeam
        )
    }

    // MARK: - Start Button Section

    private var startButtonSection: some View {
        VStack(spacing: Spacing.md) {
            // Validation message
            if !canStartGame {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "info.circle.fill")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)

                    Text(validationMessage)
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }

            // Start button
            Button(action: {
                startGame()
            }) {
                HStack(spacing: Spacing.md) {
                    Image(systemName: "play.circle.fill")
                        .font(.title2)

                    Text("Start New Game")
                        .font(.title3)
                        .fontWeight(.bold)

                    Spacer()

                    Image(systemName: "arrow.right")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge)
                        .fill(canStartGame ? AppTheme.baseballKubb : AppTheme.textSecondary.opacity(0.3))
                )
                .shadow(color: canStartGame ? AppTheme.shadowStrong : Color.clear, radius: 12, y: 6)
            }
            .disabled(!canStartGame)
            .animation(.easeInOut(duration: 0.2), value: canStartGame)
        }
    }

    private var validationMessage: String {
        if awayTeam.isEmpty && homeTeam.isEmpty {
            return "Enter both team names to start"
        } else if awayTeam.isEmpty {
            return "Enter away team name"
        } else if homeTeam.isEmpty {
            return "Enter home team name"
        } else if awayTeam == homeTeam {
            return "Team names must be different"
        } else if selectedUserTeam == nil {
            return "Select which team you're on"
        }
        return ""
    }

    // MARK: - Helpers

    private var canStartGame: Bool {
        !awayTeam.isEmpty && !homeTeam.isEmpty && awayTeam != homeTeam && selectedUserTeam != nil
    }

    private func startGame() {
        guard let userTeam = selectedUserTeam else { return }
        sessionManager.startNewGame(awayTeam: awayTeam, homeTeam: homeTeam, userTeam: userTeam)
        navigateToGame = true
    }
}

// MARK: - Active Game View

struct BaseballKubbActiveGameView: View {
    @ObservedObject var sessionManager: BaseballKubbSessionManager
    @State private var showingHitModal = false
    @State private var showingHalfSummary = false
    @State private var showingMenu = false
    @State private var showingSendToWatchSheet = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if sessionManager.currentSession?.gameOver == true {
                // Game Over
                gameOverView
            } else if showingHalfSummary {
                // Half Summary
                BaseballKubbHalfSummaryView(
                    sessionManager: sessionManager,
                    showingHalfSummary: $showingHalfSummary
                )
            } else {
                // Active Game
                activeGameView
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(
            leading: Button("Back") {
                dismiss()
            },
            trailing: HStack(spacing: 16) {
                WatchIconButton {
                    showingSendToWatchSheet = true
                }

                Button("Menu") {
                    showingMenu = true
                }
            }
        )
        .sheet(isPresented: $showingHitModal) {
            BaseballKubbHitModalView(
                sessionManager: sessionManager,
                showingHitModal: $showingHitModal,
                showingHalfSummary: $showingHalfSummary
            )
        }
        .sheet(isPresented: $showingMenu) {
            BaseballKubbMenuView(
                sessionManager: sessionManager,
                showingMenu: $showingMenu
            )
        }
        .sheet(isPresented: $showingSendToWatchSheet) {
            SendToWatchSheet(
                isPresented: $showingSendToWatchSheet,
                sessionType: "Baseball Kubb",
                onSendToWatch: {
                    handleSendToWatch()
                }
            )
        }
    }

    // MARK: - Navigation Title

    private var navigationTitle: String {
        if let session = sessionManager.currentSession, !session.gameOver {
            return "Inning \(session.currentInning) - \(session.isTop ? "Top" : "Bottom")"
        }
        return "Baseball Kubb"
    }

    // MARK: - Active Game View

    private var activeGameView: some View {
        ZStack(alignment: .top) {
            AppTheme.surface.ignoresSafeArea()

            VStack(spacing: 0) {
                // Sticky Scoreboard
                BaseballKubbStickyScoreboard(sessionManager: sessionManager)

                // Scrollable Content
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: Spacing.sectionSpacing) {
                        // Game State
                        BaseballKubbGameStateView(sessionManager: sessionManager)

                        // Throw History
                        BaseballKubbThrowHistoryCard(sessionManager: sessionManager)

                        // Throw Controls (Improved)
                        BaseballKubbThrowControlsImproved(
                            sessionManager: sessionManager,
                            showingHitModal: $showingHitModal,
                            showingHalfSummary: $showingHalfSummary
                        )
                    }
                    .padding(Spacing.screenPadding)
                }
            }
        }
        .onAppear {
            sessionManager.setupWatchConnectivity()
            sessionManager.sendSessionStateToWatch()
        }
    }

    // MARK: - Game Over View

    private var gameOverView: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: Spacing.sectionSpacing) {
                // Winner Header
                VStack(spacing: Spacing.md) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 60))
                        .foregroundColor(AppTheme.trophy)

                    Text("Game Over!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.textPrimary)

                    if let session = sessionManager.currentSession {
                        Text("Winner: \(session.winner == "away" ? session.awayTeam : session.homeTeam)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.success)
                    }
                }
                .padding(Spacing.xl)
                .frame(maxWidth: .infinity)
                .background(AppTheme.cardBackground)
                .cornerRadius(AppTheme.cornerRadiusLarge)
                .shadow(color: AppTheme.shadowMedium, radius: 8, y: 4)

                // Final Score
                if let session = sessionManager.currentSession {
                    VStack(spacing: Spacing.md) {
                        SectionHeader.simple("Final Score")

                        VStack(spacing: Spacing.sm) {
                            HStack {
                                Text(session.awayTeam)
                                    .font(.body)
                                Spacer()
                                Text("\(session.awayScore)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("(👑 \(session.awayKings))")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textSecondary)
                            }

                            Divider()

                            HStack {
                                Text(session.homeTeam)
                                    .font(.body)
                                Spacer()
                                Text("\(session.homeScore)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("(👑 \(session.homeKings))")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                        }
                        .padding(Spacing.md)
                        .background(AppTheme.surface)
                        .cornerRadius(AppTheme.cornerRadiusMedium)
                    }
                }

                // New Game Button
                Button("New Game") {
                    sessionManager.resetSession()
                    dismiss()
                }
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.lg)
                .background(AppTheme.primary)
                .cornerRadius(AppTheme.cornerRadiusLarge)
                .shadow(color: AppTheme.shadowMedium, radius: 8, y: 4)
            }
            .padding(Spacing.screenPadding)
        }
    }

    private func handleSendToWatch() {
        guard let session = sessionManager.currentSession else { return }

        // Create session state
        let sessionState = WatchSessionState(
            sessionType: "Baseball Kubb",
            isActive: true,
            currentRound: session.currentInning,
            totalRounds: 9, // Baseball Kubb is 9 innings
            currentPhase: session.isTop ? "Top" : "Bottom",
            isWatchMode: false,
            targetBatons: nil,
            currentBatons: nil,
            hasALine: nil,
            currentAttackingTeam: session.isTop ? 1 : 2  // 1 for away team (top), 2 for home team (bottom)
        )

        // Send to watch
        WatchConnectivityManager.shared.sendSessionToWatch(
            sessionType: "Baseball Kubb",
            sessionState: sessionState
        )

        // Immediately request input on watch so user can start recording
        sessionManager.requestWatchBatonInput()
    }
}

// MARK: - Helper Components

private struct BaseballKubbStickyScoreboard: View {
    @ObservedObject var sessionManager: BaseballKubbSessionManager

    var body: some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                // Inning and Half
                VStack(alignment: .leading, spacing: 2) {
                    Text("Inning \(sessionManager.currentSession?.currentInning ?? 1)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.textPrimary)

                    Text(sessionManager.currentSession?.isTop == true ? "Top" : "Bottom")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }

                Spacer()

                // Scores
                HStack(spacing: Spacing.lg) {
                    VStack(spacing: 2) {
                        Text(sessionManager.currentSession?.awayTeam ?? "Away")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                        Text("\(sessionManager.currentSession?.awayScore ?? 0)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.baseballKubb)
                    }

                    Text("-")
                        .font(.title3)
                        .foregroundColor(AppTheme.textSecondary)

                    VStack(spacing: 2) {
                        Text(sessionManager.currentSession?.homeTeam ?? "Home")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                        Text("\(sessionManager.currentSession?.homeScore ?? 0)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.baseballKubb)
                    }
                }
            }
        }
        .padding(Spacing.md)
        .background(
            AppTheme.cardBackground
                .shadow(color: AppTheme.shadowStrong, radius: 8, y: 4)
        )
    }
}

private struct BaseballKubbThrowHistoryCard: View {
    @ObservedObject var sessionManager: BaseballKubbSessionManager

    var halfInningThrows: [(type: String, count: Int)] {
        let history = sessionManager.currentSession?.throwHistory ?? []

        // Find throws since the last half inning started (max 6)
        var batonThrows: [(type: String, count: Int)] = []
        let maxThrows = min(6, history.count)

        for i in stride(from: history.count - maxThrows, to: history.count, by: 1) where i >= 0 {
            guard i > 0 else { continue }
            let current = history[i]
            let previous = history[i - 1]

            if current.fieldKubbs > previous.fieldKubbs {
                batonThrows.append(("field", current.fieldKubbs - previous.fieldKubbs))
            } else if current.awayBaselineKubbs > previous.awayBaselineKubbs || current.homeBaselineKubbs > previous.homeBaselineKubbs {
                batonThrows.append(("baseline", 1))
            } else if current.awayKings > previous.awayKings || current.homeKings > previous.homeKings {
                batonThrows.append(("king", 1))
            } else {
                batonThrows.append(("miss", 0))
            }
        }

        return batonThrows
    }

    var body: some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                Text("This Half Inning")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.textSecondary)

                Spacer()

                if !halfInningThrows.isEmpty {
                    Text("\(halfInningThrows.filter { $0.count > 0 }.count)/\(halfInningThrows.count)")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }

            HStack(spacing: Spacing.xs) {
                ForEach(0..<6, id: \.self) { index in
                    if index < halfInningThrows.count {
                        let throwData = halfInningThrows[index]
                        ZStack {
                            Circle()
                                .fill(throwColor(for: throwData.type))
                                .frame(width: 32, height: 32)

                            if throwData.count > 1 {
                                ZStack {
                                    Circle()
                                        .fill(.white)
                                        .frame(width: 18, height: 18)

                                    Text("\(throwData.count)")
                                        .font(.system(size: 11, weight: .black))
                                        .foregroundColor(throwColor(for: throwData.type))
                                }
                            } else if throwData.count > 0 {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "xmark")
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

    private func throwColor(for type: String) -> Color {
        switch type {
        case "field": return AppTheme.success
        case "baseline": return AppTheme.baseballKubb
        case "king": return AppTheme.trophy
        default: return AppTheme.error
        }
    }
}

private struct BaseballKubbThrowControlsImproved: View {
    @ObservedObject var sessionManager: BaseballKubbSessionManager
    @Binding var showingHitModal: Bool
    @Binding var showingHalfSummary: Bool

    var body: some View {
        VStack(spacing: Spacing.md) {
            Text("Baton \(sessionManager.currentSession?.currentBaton ?? 1)")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.textPrimary)

            // Hit/Miss Buttons
            HStack(spacing: Spacing.md) {
                // Miss Button
                Button(action: {
                    sessionManager.recordMiss()
                    checkHalfInningEnd()
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
                    .background(sessionManager.currentSession?.isHalfInningOver ?? false ? AppTheme.textSecondary : AppTheme.error)
                    .cornerRadius(AppTheme.cornerRadiusMedium)
                    .shadow(color: AppTheme.shadowMedium, radius: 4, y: 2)
                }
                .disabled(sessionManager.currentSession?.isHalfInningOver ?? false)

                // Hit Button
                Button(action: {
                    showingHitModal = true
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
                    .background(sessionManager.currentSession?.isHalfInningOver ?? false ? AppTheme.textSecondary : AppTheme.success)
                    .cornerRadius(AppTheme.cornerRadiusMedium)
                    .shadow(color: AppTheme.shadowMedium, radius: 4, y: 2)
                }
                .disabled(sessionManager.currentSession?.isHalfInningOver ?? false)
            }

            // Undo Button
            if !(sessionManager.currentSession?.throwHistory.isEmpty ?? true) {
                Button(action: {
                    sessionManager.undoLastThrow()
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
        .padding(Spacing.md)
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadiusMedium)
        .shadow(color: AppTheme.shadowMedium, radius: 4, y: 2)
    }

    private func checkHalfInningEnd() {
        if sessionManager.currentSession?.isHalfInningOver == true {
            showingHalfSummary = true
        }
    }
}

// MARK: - Preview

#Preview {
    BaseballKubbViewRedesigned()
}
